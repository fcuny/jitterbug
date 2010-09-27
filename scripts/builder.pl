#!/usr/bin/env perl

use strict;
use warnings;

use Redis;
use JSON;
use YAML qw/LoadFile Dump/;
use File::Spec;
use File::Path qw/rmtree/;
use File::Basename;
use Git::Repository;

$|++;

my $conf  = LoadFile('config.yml');
my $redis = Redis->new( server => $conf->{redis} );
my $key   = join( ':', 'jitterbug', 'tasks' );

while (1) {
    my $task_key = $redis->spop($key);
    if ($task_key) {
        my $task    = $redis->get($task_key);
        my $desc    = JSON::decode_json($task);
        my $repo    = $desc->{repo} . '.git';
        my $commit  = delete $desc->{id};
        my $project = delete $desc->{project};

        my $report_path =
          File::Spec->catdir( $conf->{jitterbug}->{reports}->{dir},
            $project, $commit );

        my $build_dir =
          File::Spec->catdir( $conf->{jitterbug}->{build}->{dir}, $project );

        my $r = Git::Repository->create( clone => $repo => $build_dir );
        $r->run( 'checkout', $commit );

        my $builder = $conf->{jitterbug}->{build_process}->{builder};
        my $res     = `$builder $build_dir $report_path`;

        rmtree($build_dir);

        $redis->del($task_key);

        my $build = {
            project => $project,
            repo    => $repo,
            commit  => $commit,
            time    => time(),
            %$desc,
        };

        my @versions = glob( $report_path . '/*' );
        foreach my $version (@versions) {
            open my $fh, '<', $version;
            my @lines  = <$fh>;
            my $result = pop @lines;
            while ( $result !~ /^Result/ ) {
                $result = pop @lines;
            }
            chomp $result;
            $result =~ s/Result:\s//;
            my ( $name, ) = basename($version);
            $name =~ s/\.txt//;
            if ( $result !~ /PASS/ ) {

                # mail author of the commit
                my $message  = $desc->{message};
                my $commiter = $desc->{author}->{email};
                my $output   = "Build failed";
                my $sha      = $desc->{commit};
                my $on_failure =
                  $conf->{jitterbug}->{build_process}->{on_failure};
                `$on_failure $commiter $message $output $sha`;
            }
            $build->{version}->{$name} = $result;
            close $fh;
        }

        my $build_key = join( ':', 'jitterbug', 'build', $commit );
        $redis->set( $build_key, JSON::encode_json($build) );

        my $project_build = join( ':', 'jitterbug', 'builds', $project );
        $redis->sadd( $project_build, $build_key );
        warn "done, next\n";
    }
    sleep 5;
}
