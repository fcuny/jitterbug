#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';

use YAML qw/LoadFile/;
use DBIx::Class::DeploymentHandler;
use SQL::Translator;

my $config = shift;
die "need configuration file" unless $config;

my $schema = 'jitterbug::Schema';

my $version = eval "use $schema; $schema->VERSION" or die $@;

print "processing version $version of $schema...\n";

my $jitterbug_conf = LoadFile($config);
my $dbix_conf      = $jitterbug_conf->{plugins}->{DBIC}->{schema};
my $s              = $schema->connect( @{ $dbix_conf->{connect_info} } );

my $dh = DBIx::Class::DeploymentHandler->new(
    {
        schema              => $s,
        databases           => [qw/ SQLite PostgreSQL MySQL /],
        sql_translator_args => { add_drop_table => 0, },
    }
);

print "generating deployment script\n";
$dh->prepare_install;

if ( $version > 1 ) {
    print "generating upgrade script\n";
    $dh->prepare_upgrade(
        {
            from_version => $version - 1,
            to_version   => $version,
            version_set  => [ $version - 1, $version ],
        }
    );

    print "generating downgrade script\n";
    $dh->prepare_downgrade(
        {
            from_version => $version,
            to_version   => $version - 1,
            version_set  => [ $version, $version - 1 ],
        }
    );
}

print "done\n";
