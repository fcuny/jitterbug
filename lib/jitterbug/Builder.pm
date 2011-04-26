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
use Git::Repository;
use jitterbug::Schema;
use Cwd;
#use Data::Dumper;

local $| = 1;
use constant DEBUG => $ENV{DEBUG} || 0;

sub new {
    my $self = bless {} => shift;

    GetOptions(
        'C|cron'         => \$self->{'cron'},
        'c|configfile=s' => \$self->{'configfile'},
        's|sleep=i'      => \$self->{'sleep'},
    ) or die "Cannot get options\n";

    $self->{'configfile'}
        or die qq{missing config.yml, use "-c config.yml" to help us find it\n};

    die "Does not exist!: " . $self->{'configfile'} unless -e $self->{'configfile'};

    return $self;
}

sub debug {
    warn @_ if DEBUG;
}

sub run {
    my $self      = shift || die "Must call run() from object\n";
    my $conf      = $self->{'conf'} = LoadFile( $self->{'configfile'} );
    my $dbix_conf = $conf->{'plugins'}{'DBIC'}{'schema'};

    debug("Loaded config file: " . $self->{'configfile'});
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

sub run_task {
    my ($self,$task)   = @_;

    my $desc    = JSON::decode_json( $task->commit->content );
    my $conf    = $self->{'conf'};
    my $buildconf = $conf->{'jitterbug'}{'build_process'};
    my $project = $task->project;

    my $dt = DateTime->now();
    $task->update({started_when => $dt});
    $desc->{'build'}{'start_time'} = $dt->epoch;
    debug("Build Start");

    my $report_path = dir(
        $conf->{'jitterbug'}{'reports'}{'dir'},
        $project->name,
        $task->commit->sha256,
    );
    my $dir = $conf->{'jitterbug'}{'build'}{'dir'};
    mkdir $dir unless -d $dir;

    my $build_dir = dir($dir, $project->name);

    my $r;
    my $repo    = $task->project->url . '.git';
    unless ($buildconf->{reuse_repo}) {
        debug("Removing $build_dir");
        rmtree($build_dir, { error => \my $err } );
        warn @$err if @$err;
        $r       = Git::Repository->create( clone => $repo => $build_dir );
    } else {
        # If this is the first time, the repo won't exist yet
        debug("build_dir = $build_dir");
        if( -d $build_dir ){
            my $pwd = getcwd;
            chdir $build_dir;
            # TODO: Error Checking
            debug("Cleaning git repo");
            system("git clean -dfx");
            debug("Fetching new commits into $repo");
            system("git fetch");
            debug("Checking out correct commit");
            system("git checkout " . $task->commit->sha256 );
            chdir $pwd;
        } else {
            debug("Creating new repo");
            my $pwd = getcwd;
            debug("pwd=$pwd");
            chdir $build_dir;
            system("git clone $repo $build_dir");
            chdir $pwd;
        }
    }
    $self->sleep(1); # avoid race conditions

    debug("Checking out " . $task->commit->sha256 . " from $repo into $build_dir\n");
    # $r->run( 'checkout', $task->commit->sha256 );
    my $pwd = getcwd;
    chdir $build_dir;
    system("git checkout " . $task->commit->sha256 );
    chdir $pwd;

    my $builder       =    $conf->{'jitterbug'}{'projects'}{$project->name}{'builder'}
                        || $conf->{'jitterbug'}{'build_process'}{'builder'};

    my $perlbrew      = $conf->{'jitterbug'}{'options'}{'perlbrew'};
    my $email_on_pass = $conf->{'jitterbug'}{'options'}{'email_on_pass'};

    debug("email_on_pass = $email_on_pass");
    debug("perlbrew      = $perlbrew");

    # If the project has custom builder variables, use those. Otherwise, use the global setting
    my $builder_variables =    $conf->{'jitterbug'}{'projects'}{$project->name}{'builder_variables'}
                            || $conf->{'jitterbug'}{'build_process'}{'builder_variables'};

    my $builder_command = "$builder_variables $builder $build_dir $report_path $perlbrew";

    debug("Going to run builder : $builder_command");
    my $res             = `$builder_command`;
    debug($res);

    $desc->{'build'}{'end_time'} = time();

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
            my $failure_cmd = sprintf("%s '%s' %s '%s' '%s' %s %s", $on_failure, $commiter, $task->project->name, $message, $output, $sha, $on_failure_cc_email);
            debug("Running failure command: $failure_cmd");

            # does it look like a module name?
            if ($on_failure =~ /::/) {
                # we should do some error checking here
                eval "require $on_failure";
                $on_failure->new($conf,$task,$output,'failure')->run;
            } else {
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
            my $pass_cmd = sprintf("%s '%s' %s '%s' '%s' %s %s", $on_pass, $commiter, $task->project->name, $message, $output, $sha, $on_pass_cc_email);
            debug("Running pass command: $pass_cmd");

            # does it look like a module name?
            if ($on_pass =~ /::/) {
                # we should do some error checking here
                eval "require $on_pass";
                $on_pass->new($conf,$task,$output, 'pass')->run;
            } else {
                system($pass_cmd);
            }
        }
        $desc->{'build'}{'version'}{$name} = $result;
        close $fh;
    }

    $task->commit->update( {
        content => JSON::encode_json($desc),
    } );
    debug("Task completed for " . $task->commit->sha256 . "\n");

    $task->delete();

    debug("Task removed from " . $task->project->name . "\n");
}

