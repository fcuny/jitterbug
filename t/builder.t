
use strict;
use warnings;
use Test::Most tests => 6;

use jitterbug::Builder;

{
    local @ARGV = qw(-c foo.yml -C);
    my $b = jitterbug::Builder->new();

    isa_ok($b,'jitterbug::Builder');
    can_ok($b,qw/run build run_task sleep/);

    is($b->{'configfile'}, 'foo.yml');
    is($b->{'cron'}, 1 );
}

{
    local @ARGV = qw(-c blarg.yml -C);
    my $b = jitterbug::Builder->new();

    throws_ok (sub {$b->run}, qr/YAML Error/i, 'nonexistent yaml file throws error');
}

{
    local @ARGV = qw(-c t/data/test.yml -C);
    my $b = jitterbug::Builder->new();
    is($b->run, 0, '->run returns 0 in cron mode');

}
