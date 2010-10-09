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

local $| = 1;

sub new {
    my $self = bless {} => shift;

    GetOptions(
        'C|cron'         => \$self->{'cron'},
        'c|configfile=s' => \$self->{'configfile'},
        's|sleep=i'      => \$self->{'sleep'},
    ) or die "Cannot get options\n";

    $self->{'configfile'}
        or die qq{missing config.yml, use "-c config.yml" to help us find it\n};

    return $self;
}

sub run {
    my $self      = shift || die "Must call run() from object\n";
    my $conf      = $self->{'conf'} = LoadFile( $self->{'configfile'} );
    my $dbix_conf = $conf->{'plugins'}{'DBIC'}{'schema'};

    $self->{'schema'}   = jitterbug::Schema->connect( @{ $dbix_conf->{'connect_info'} } );
    $self->{'interval'} = $self->{'sleep'}                         ||
                          $conf->{'jitterbug'}{'builder'}{'sleep'} ||
                          30;

    return $self->build;
}

sub build {
    my $self  = shift;
    my @tasks = $self->{'schema'}->resultset('Task')->all();

    while (1) {
        foreach my $task (@tasks) {
            $task ? $self->run_task($task) : sleep $self->{'interval'};
        }

        $self->{'cron'} and return 0;

        warn "done\n";
        sleep 5;
    }

    return 1;
}

sub run_task {
    my $self   = shift;
    my ($task) = @_;
    my $desc   = JSON::decode_json( $task->commit->content );
    my $conf   = $self->{'conf'};

    $desc->{'build'}{'start_time'} = time();

    my $report_path = dir(
        $conf->{'jitterbug'}{'reports'}{'dir'},
        $task->project->name,
        $task->commit->sha256,
    );

    my $build_dir = dir(
        $conf->{'jitterbug'}{'build'}{'dir'},
        $task->project->name,
    );

    my $repo    = $task->project->url . '.git';
    my $r       = Git::Repository->create( clone => $repo => $build_dir );
    $r->run( 'checkout', $task->commit->sha256 );

    my $builder = $conf->{'jitterbug'}{'build_process'}{'builder'};
    my $res     = `$builder $build_dir $report_path`;

    rmtree($build_dir);

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
        if ( !$result || ($result && $result !~ /PASS/ )) {
            # mail author of the commit
            $result = "FAIL";
            my $message  = $desc->{'message'};
            my $commiter = $desc->{'author'}{'email'};
            my $output   = "Build failed";
            my $sha      = $desc->{'id'};
            my $on_failure =
                $conf->{'jitterbug'}{'build_process'}{'on_failure'};
            `$on_failure $commiter $message $output $sha`;
        }
        $desc->{'build'}{'version'}{$name} = $result;
        close $fh;
    }

    $task->commit->update( {
        content => JSON::encode_json($desc),
    } );

    $task->delete();
}

