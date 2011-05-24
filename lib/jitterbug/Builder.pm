package jitterbug::Builder;

use strict;
use warnings;

use DateTime;
use YAML qw/LoadFile Dump/;
use JSON;
use File::Path qw/rmtree/;
use Path::Class;
use Getopt::Long qw/:config no_ignore_case/;
use File::Basename;
use jitterbug::Schema;
use Cwd;
#use Data::Dumper;

local $| = 1;
use constant DEBUG => $ENV{DEBUG} || 0;

sub new {
    my $self = bless {} => shift;

    GetOptions(
        'C|cron'         => \$self->{'cron'},
        'c|config=s' => \$self->{'config'},
        's|sleep=i'      => \$self->{'sleep'},
    ) or die "Cannot get options\n";

    $self->{'config'}
        or die qq{missing config.yml, use "-c config.yml" to help us find it\n};

    die "Does not exist!: " . $self->{'config'} unless -e $self->{'config'};

    return $self;
}

sub debug {
    warn @_ if DEBUG;
}

sub run {
    my $self      = shift || die "Must call run() from object\n";
    my $conf      = $self->{'conf'} = LoadFile( $self->{'config'} );
    my $dbix_conf = $conf->{'plugins'}{'DBIC'}{'schema'};

    debug("Loaded config file: " . $self->{'config'});
    debug("Connection Info: " . join ':', @{ $dbix_conf->{'connect_info'} });

    $self->{'schema'}   = jitterbug::Schema->connect( @{ $dbix_conf->{'connect_info'} } );
    $self->{'interval'} = $self->{'sleep'}                         ||
                          $conf->{'jitterbug'}{'builder'}{'sleep'} ||
                          30;

    return $self->build;
}

sub build {
    my $self  = shift;

    while (1) {
        my @tasks = $self->{'schema'}->resultset('Task')->all();
        debug("Found " . scalar(@tasks) . " tasks");

        foreach my $task (@tasks) {
            $task ? $self->run_task($task) : $self->sleep;
        }

        $self->{'cron'} and return 0;

        $self->sleep(5);
    }

    return 1;
}

sub sleep {
    my ($self, $interval) = @_;
    $interval ||= $self->{'interval'};
    debug("sleeping for $interval seconds\n");
    sleep $interval;
}

sub _clone_into {
    my ($repo, $dir) = @_;
    my $pwd = getcwd;
    chdir $dir;

    debug("cloning $repo into $dir");
    system("git clone $repo $dir");

    chdir $pwd;
}

sub _prepare_git_repo {
    my ($self, $task, $buildconf, $build_dir, $cached_repo_dir) = @_;

    my $repo    = $task->project->url;
    my $name    = $task->project->name;

    debug("Removing $build_dir");
    rmtree($build_dir, { error => \my $err } );
    warn @$err if @$err;

    # If we aren't reusing/caching git repos, clone from remote into the build dir
    unless ($buildconf->{reuse_repo}) {
        _clone_into($repo, $build_dir);
    } else {
        # We are caching git repos, so we clone a new repo from our local
        # cached git repo, then checkout the correct sha1

        debug("build_dir = $build_dir");
        unless ( -d catfile($cached_repo_dir,$name) ) {
            # If this is the first time, the repo won't exist yet
            # Clone it into our cached repo directory
            _clone_into($repo, $cached_repo_dir);
        }
        my $pwd = getcwd;

        chdir $cached_repo_dir;
        # TODO: Error Checking

        debug("Fetching new commits into $cached_repo_dir");
        system("git fetch --prune");
        chdir $pwd;

        debug("Cloning from cached repo $cached_repo_dir into $build_dir");

        _clone_into($cached_repo_dir, $build_dir);
        chdir $build_dir;

        $self->sleep(1); # avoid race conditions

        # TODO: this may fail on non-unixy systems
        debug("checking out " . $task->commit->sha256);
        system("git checkout " . $task->commit->sha256 . "&>/dev/null" );

        chdir $pwd;
    }
}

sub build_task {
    my ($self, $conf, $project, $task, $report_path) = @_;

    my $buildconf = $conf->{'jitterbug'}{'build_process'};
    my $dir       = $conf->{'jitterbug'}{'build'}{'dir'};

    mkdir $dir unless -d $dir;

    my $build_dir = dir($dir, $project->name);
    my $cached_repo_dir = dir($dir, 'cached');

    mkdir $cached_repo_dir unless -d $cached_repo_dir;

    $self->_prepare_git_repo($task, $buildconf, $build_dir, $cached_repo_dir);

    my $builder       =    $conf->{'jitterbug'}{'projects'}{$project->name}{'builder'}
                        || $conf->{'jitterbug'}{'build_process'}{'builder'};

    my $perlbrew      = $conf->{'jitterbug'}{'options'}{'perlbrew'};

    debug("perlbrew      = $perlbrew");

    # If the project has custom builder variables, use those. Otherwise, use the global setting
    my $builder_variables =    $conf->{'jitterbug'}{'projects'}{$project->name}{'builder_variables'}
                            || $conf->{'jitterbug'}{'build_process'}{'builder_variables'} || '';

    my $builder_command = "$builder_variables $builder $build_dir $report_path $perlbrew";

    debug("Going to run builder : $builder_command");
    my $res             = `$builder_command`;
    debug($res);
    return $res;
}

sub run_task {
    my ($self,$task)   = @_;

    my $desc    = JSON::decode_json( $task->commit->content );
    my $conf    = $self->{'conf'};
    my $project = $task->project;
    my $report_path = dir(
        $conf->{'jitterbug'}{'reports'}{'dir'},
        $project->name,
        $task->commit->sha256,
    );

    my $dt = DateTime->now();
    $task->update({started_when => $dt});
    $desc->{'build'}{'start_time'} = $dt->epoch;
    debug("Build Start");

    $self->build_task($conf, $project, $task, $report_path);

    $desc->{'build'}{'end_time'} = time();

    $self->_parse_results($report_path, $conf, $task, $desc);

    $task->commit->update( {
        content => JSON::encode_json($desc),
    } );
    debug("Task completed for " . $task->commit->sha256 . "\n");

    $task->delete();

    debug("Task removed from " . $task->project->name . "\n");
}

sub _parse_results {
    my ($self, $report_path, $conf, $task, $desc) = @_;
    my $email_on_pass = $conf->{'jitterbug'}{'options'}{'email_on_pass'};
    debug("email_on_pass = $email_on_pass");

    my @versions = glob( $report_path . '/*' );
    foreach my $version (@versions) {
        open my $fh, '<', $version;
        my ($result, $lines);
        while (<$fh>){
            $lines .= $_;
        }
        # if $result is undefined, either there was a build failure
        # or the test output is not from a TAP harness
        ($result) = $lines =~ /Result:\s(\w+)/;
        my ( $name, ) = basename($version);
        $name =~ s/\.txt//;

        debug("Result of test suite is $result");

        # TODO: Unify this code

        if ( !$result || ($result && $result !~ /PASS/ )) {
            debug("Emailing FAIL report");
            # mail author of the commit
            $result = "FAIL";
            my $message             = $desc->{'message'};
            my $commiter            = $desc->{'author'}{'email'};
            my $output              = $lines;
            my $sha                 = $desc->{'id'};
            my $on_failure          = $conf->{'jitterbug'}{'build_process'}{'on_failure'};
            my $on_failure_cc_email = $conf->{'jitterbug'}{'build_process'}{'on_failure_cc_email'};

            $message  =~ s/'/\\'/g; $commiter =~ s/'/\\'/g; $output =~ s/'/\\'/g;
            # does it look like a module name?
            if ($on_failure =~ /::/) {
                # we should do some error checking here
                eval "require $on_failure";
                $on_failure->new($conf,$task,$output,'failure')->run;
            } else {
                my $failure_cmd = sprintf("%s '%s' %s '%s' '%s' %s %s", $on_failure, $commiter, $task->project->name, $message, $output, $sha, $on_failure_cc_email);
                debug("Running failure command: $failure_cmd");

                system($failure_cmd);
            }
        } elsif ($email_on_pass) {
            debug("Emailing PASS report");
            $result = "PASS";
            my $message          = $desc->{'message'};
            my $commiter         = $desc->{'author'}{'email'};
            my $output           = $lines;
            my $sha              = $desc->{'id'};
            my $on_pass          = $conf->{'jitterbug'}{'build_process'}{'on_pass'};
            my $on_pass_cc_email = $conf->{'jitterbug'}{'build_process'}{'on_pass_cc_email'};

            $message  =~ s/'/\\'/g; $commiter =~ s/'/\\'/g; $output =~ s/'/\\'/g;

            # does it look like a module name?
            if ($on_pass =~ /::/) {
                # we should do some error checking here
                eval "require $on_pass";
                $on_pass->new($conf,$task,$output, 'pass')->run;
            } else {
                my $pass_cmd = sprintf("%s '%s' %s '%s' '%s' %s %s", $on_pass, $commiter, $task->project->name, $message, $output, $sha, $on_pass_cc_email);
                debug("Running pass command: $pass_cmd");
                system($pass_cmd);
            }
        }
        $desc->{'build'}{'version'}{$name} = $result;
        close $fh;
    }
}
