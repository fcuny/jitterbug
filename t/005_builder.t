
use strict;
use warnings;
use Test::Most tests => 7;
use Data::Dumper;

use jitterbug::Builder;

{
    local @ARGV = qw(-c t/data/test.yml -C);
    my $b = jitterbug::Builder->new();

    isa_ok($b,'jitterbug::Builder');
    can_ok($b,qw/run build run_task sleep/);

    is($b->{'configfile'}, 't/data/test.yml');
    is($b->{'cron'}, 1 );
}

{
    local @ARGV = qw(-c blarg.yml -C);

    throws_ok (sub {
        my $b = jitterbug::Builder->new();
    }, qr/Does not exist/i, 'nonexistent yaml file throws error');
}

{
    local @ARGV = qw(-c t/data/test.yml -C);
    my $b = jitterbug::Builder->new();
    isa_ok($b, 'jitterbug::Builder');
    is($b->{'configfile'}, 't/data/test.yml');
    #warn Dumper [ $b ];

    is($b->run, 0, '->run returns 0 in cron mode');
    cmp_deeply($b->{'conf'}, {
        'configfile' => 't/data/test.yml',
        'cron'       => 1,
        'sleep'      => undef
    });


}

