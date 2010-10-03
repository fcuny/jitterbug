#!/usr/bin/env perl
use strict;
use warnings;

use jitterbug::Schema;

use YAML qw/LoadFile/;
use JSON;

my $conf = shift || die "config is missing";
my $data = shift || die "data is missing";

$conf = LoadFile($conf);
$data = LoadFile($data);

my $schema = jitterbug::Schema->connect(
    @{ $conf->{plugins}->{DBIC}->{schema}->{connect_info} } );

my $project = $schema->resultset('Project')->create(
    {
        name        => $data->{desc}->{name},
        url         => $data->{desc}->{url},
        description => $data->{desc}->{description},
        owner       => JSON::encode_json( $data->{desc}->{owner} ),
    }
);

foreach my $build ( @{ $data->{builds} } ) {
    my $sha256    = delete $build->{commit};
    my $timestamp = $build->{timestamp};
    my $tests = delete $build->{version};
    $build->{build}->{version} = $tests;
    $schema->resultset('Commit')->create(
        {
            sha256    => $sha256,
            projectid => $project->projectid,
            timestamp => $timestamp,
            content   => JSON::encode_json($build),
        }
    );
}
