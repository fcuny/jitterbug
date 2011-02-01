package jitterbug::Builder;

use strict;
use warnings;

use YAML qw/LoadFile Dump/;
use JSON;
use File::Path qw/rmtree/;
use Path::Class;
use Getopt::Long qw/:config no_ignore_case/;
use File::Basename;
use Git::Repository;
use jitterbug::Schema;
#use Data::Dumper;

local $| = 1;
use constant DEBUG => 1;

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
    my $self   = shift;
    my ($task) = @_;
    my $desc   = JSON::decode_json( $task->commit->content );
    my $conf   = $self->{'conf'};

    $desc->{'build'}{'start_time'} = time();
    debug("Build Start");

    my $report_path = dir(
        $conf->{'jitterbug'}{'reports'}{'dir'},
        $task->project->name,
        $task->commit->sha256,
    );

    my $build_dir = dir(
        $conf->{'jitterbug'}{'build'}{'dir'},
        $task->project->name,
    );

    debug("Removing $build_dir");
    rmtree($build_dir, { error => \my $err } );
    warn @$err if @$err;

    $self->sleep(1); # avoid race conditions

    my $repo    = $task->project->url . '.git';
    my $r       = Git::Repository->create( clone => $repo => $build_dir );

    debug("Checking out " . $task->commit->sha256 . " from $repo into $build_dir\n");
    $r->run( 'checkout', $task->commit->sha256 );

    my $builder         = $conf->{'jitterbug'}{'build_process'}{'builder'};

    my $perlbrew = $conf->{'options'}{'perlbrew'} || 1;
    my $builder_variables = $conf->{'jitterbug'}{'build_process'}{'builder_variables'};

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
        ($result) = $lines =~ /Result:\s(\w+)/;
        my ( $name, ) = basename($version);
        $name =~ s/\.txt//;

        debug("Result of test suite is $result");

        if ( !$result || ($result && $result !~ /PASS/ )) {
            # mail author of the commit
            $result = "FAIL";
            my $message          = $desc->{'message'};
            my $commiter         = $desc->{'author'}{'email'};
            my $output           = $lines;
            my $sha              = $desc->{'id'};
            my $on_failure       = $conf->{'jitterbug'}{'build_process'}{'on_failure'};
            my $on_failure_cc_email = $conf->{'jitterbug'}{'build_process'}{'on_failure_cc_email'};

            $message  =~ s/'/\\'/g; $commiter =~ s/'/\\'/g; $output =~ s/'/\\'/g;
            my $failure_cmd = sprintf("%s '%s' %s '%s' '%s' %s %s", $on_failure, $commiter, $task->project->name, $message, $output, $sha, $on_failure_cc_email);
            debug("Running failure command: $failure_cmd");

            # does it look like a module name?
            if ($on_failure =~ /::/) {
                # we should do some error checking here
                eval "require $on_failure";
                $on_failure->new($conf,$task,$output)->run;
            } else {
                system($failure_cmd);
            }
        } elsif ($conf->{'options'}{'email_on_pass'}) {
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

            # TODO: create perl pass emailer
            system($pass_cmd);
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

