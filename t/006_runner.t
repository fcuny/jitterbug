
use strict;
use warnings;
use Test::Most tests => 3;
use Data::Dumper;

use jitterbug::Runner;

{
    local @ARGV = qw(-c t/data/test.yml);
    my $b = jitterbug::Runner->new();

    isa_ok($b,'jitterbug::Runner');
    can_ok($b,qw/new run run_task sleep/);

}

{
    local @ARGV = qw(-c blarg.yml);
    throws_ok (sub {
        my $b = jitterbug::Runner->new('blarg.yml');
    }, qr/Does not exist/i, 'nonexistent yaml file throws error');
}

