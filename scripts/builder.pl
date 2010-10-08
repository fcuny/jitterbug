#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use YAML qw/LoadFile Dump/;
use File::Spec;
use File::Path qw/rmtree/;
use File::Basename;
use Git::Repository;
use jitterbug::Schema;

$|++;

my $conf_file = shift || die "config.yml is missing";
my $conf      = LoadFile($conf_file);
my $dbix_conf = $conf->{plugins}->{DBIC}->{schema};
my $schema    = jitterbug::Schema->connect( @{ $dbix_conf->{connect_info} } );
my $interval  = $conf->{jitterbug}->{builder}->{sleep} || 30;

while (1) {
    my $task = $schema->resultset('Task')->search()->single();

    unless ($task) {
        sleep $interval;
        next;
    }

    my $desc    = JSON::decode_json($task->commit->content);
    $desc->{build}->{start_time} = time();

    my $report_path = File::Spec->catdir( $conf->{jitterbug}->{reports}->{dir},
        $task->project->name, $task->commit->sha256 );
    my $build_dir = File::Spec->catdir( $conf->{jitterbug}->{build}->{dir},
        $task->project->name );

    my $repo    = $task->project->url . '.git';
    my $r = Git::Repository->create( clone => $repo => $build_dir );
    $r->run( 'checkout', $task->commit->sha256 );

    my $builder = $conf->{jitterbug}->{build_process}->{builder};
    my $res     = `$builder $build_dir $report_path`;

    rmtree($build_dir);

    $desc->{build}->{end_time} = time();

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
            my $message  = $desc->{message};
            my $commiter = $desc->{author}->{email};
            my $output   = "Build failed";
            my $sha      = $desc->{id};
            my $on_failure =
                $conf->{jitterbug}->{build_process}->{on_failure};
            `$on_failure $commiter $message $output $sha`;
        }
        $desc->{build}->{version}->{$name} = $result;
        close $fh;
    }

    $task->commit->update({
        content => JSON::encode_json($desc),
    });
    $task->delete();
    warn "done\n";
    sleep 5;
}
