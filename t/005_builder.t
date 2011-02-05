
use strict;
use warnings;
use Test::Most tests => 2;
use Data::Dumper;

use jitterbug::Runner;

{
    local @ARGV = qw(-c t/data/test.yml);
    my $r = jitterbug::Runner->new();
    isa_ok($r, 'jitterbug::Runner');
    warn Dumper [ $r ];
    is($r->{'configfile'}, 't/data/test.yml');

    system("$^X scripts/deploy_schema t/data/test.yml");

    is($r->run, 0, '->run returns 0 in cron mode');

    cmp_deeply($r->{'conf'}, {
        'configfile' => 't/data/test.yml',
        'cron'       => 1,
        'sleep'      => undef
    });

}

