package jitterbug::Builder;

use strict;
use warnings;

use jitterbug::Schema;
use Git::Repository;
use Carp;
use Email::Stuff;
use Email::Sender::Simple qw/sendmail/;
use JSON;
use YAML qw/LoadFile Dump/;
use DateTime;
use IPC::Run3;
use Try::Tiny;
use Path::Class;
use File::Slurp;
use File::Basename;
use File::Path qw/rmtree/;
use Getopt::Long qw/:config no_ignore_case/;
use FindBin '$Bin';
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
    carp @_ if DEBUG;
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
    my $self   = shift;
    my ($task) = @_;
    my $desc   = JSON::decode_json( $task->commit->content );
    my $conf   = $self->{'conf'};
    my $buildconf = $conf->{'jitterbug'}{'build_process'};

    my $dt = DateTime->now();
    $task->update({started_when => $dt});
    $desc->{'build'}{'start_time'} = $dt->epoch;
    debug("Build Start");

    my $report_path = dir(
        $conf->{'jitterbug'}{'reports'}{'dir'},
        $task->project->name,
        $task->commit->sha256,
    );
    my $dir = $conf->{'jitterbug'}{'build'}{'dir'};
    mkdir $dir unless -d $dir;

    my $build_dir = dir($dir, $task->project->name);
    chdir $build_dir;

    my $repo;
    my $repo_addr = $task->project->url . '.git';

    # hack to force ssh protocol for clone
    if ($conf->{'jitterbug'}{'build_process'}{'force_ssh'}) {
        $repo_addr =~ s#https://github.com/#git\@github.com:#;
    }

    unless ($buildconf->{reuse_repo}) {
        debug("Removing $build_dir");
        rmtree($build_dir, { error => \my $err } );
        debug @$err if @$err;

        $repo = Git::Repository->create( clone => $repo_addr => $build_dir->stringify );
    } else {
        # If this is the first time, the repo won't exist yet
        if( -d $build_dir ){
            # TODO: Error Checking
            $repo = Git::Repository->new( work_tree => $build_dir->stringify );
            $repo->run(qw/clean -dfx/)                     and debug("Cleaning git repo");
            $repo->run('fetch')                            and debug("Fetching new commits into $repo_addr");
            $repo->run('checkout', $task->commit->sha256)  and debug("Checking out correct commit");
        } else {
            debug("Creating new repo");
            $repo = Git::Repository->create( clone => $repo_addr => $build_dir->stringify );
        }
    }
    $self->sleep(1); # avoid race conditions

    debug("Checking out " . $task->commit->sha256 . " from $repo_addr into $build_dir\n");
    $repo->run('checkout', $task->commit->sha256);

    my $builder            = $conf->{'jitterbug'}{'build_process'}{'builder'};
    my $builder_variables  = $conf->{'jitterbug'}{'build_process'}{'builder_variables'};
    my $perlbrew           = $conf->{'jitterbug'}{'options'}{'perlbrew'};
    debug("perlbrew = $perlbrew");

    my @builder_command = grep defined, (
        $builder_variables,
        "${Bin}/${builder}",
        $build_dir,
        $report_path,
        $perlbrew
    );

    debug('Going to run builder : ' . join ' ', @builder_command);
    run3 \@builder_command, undef, \my $res;

    $desc->{'build'}{'end_time'} = time();

    my @versions = glob( $report_path . '/*' );
    foreach my $version (@versions) {
        my $output = read_file $version;

        # if $result is undefined, either there was a build failure
        # or the test output is not from a TAP harness
        my ($result) = $output =~ /Result:\s(\w+)/;
        debug("Result of test suite is $result");

        my ($name)   = basename($version);
        $name =~ s/\.txt//;

        my $res
            = ( !$result || ($result && $result !~ /PASS/ )) ? 'failure'
            : 'pass';

        # mail author of the commit
        my $send_email_to_committer = $conf->{'jitterbug'}{'build_process'}{'send_email_to_committer'};
        my $committer   = $send_email_to_committer ? ", @{[ $desc->{'author'}{'email'} ]}" : '';
        my $from        = $conf->{'jitterbug'}{'build_process'}{'from_email'};
        my $to          = $conf->{'jitterbug'}{'build_process'}{"on_${res}_to_email"};
        my $cc_email    = $conf->{'jitterbug'}{'build_process'}{"on_${res}_cc_email"};
        my $cmd         = $conf->{'jitterbug'}{'build_process'}{"on_${res}"};
        my $subj_prefix = $conf->{'jitterbug'}{'build_process'}{"on_${res}_subject_prefix"};

        my $sha         = substr $desc->{'id'}, 0, 6;
        my $message     = $desc->{'message'};

        my $subject     = "${subj_prefix} @{[ $task->project->name ]} \@ ${sha}..";

        try {
            my $email = Email::Stuff->from     ($from                  )
                                    ->subject  ($subject               )
                                    ->to       ("${to} ${committer}"   )
                                    ->text_body("${message}\n${output}");
            $email    = $email->cc($cc_email) if $cc_email;
            $email    = $email->email;

            # does it look like a module name?
            if ($cmd =~ /::/) {
                require $cmd;
                $cmd->new($conf, $task, $output,'failure', $email)->run;
            } elsif ($cmd) {
                # if on_pass / on_failure is set to truth, dispatch an email
                debug("Emailing ${res} report");
                sendmail($email);
            }
        }
        catch {
            debug $_;
        };

        # save our result
        $desc->{'build'}{'version'}{$name} = $result;
    }

    $task->commit->update({ content => JSON::encode_json($desc) });
    $task->delete();
    debug("[@{[ $task->project->name ]} : @{[ substr $task->commit->sha256, 0, 6 ]}] completed. Removed.");
}

1;
