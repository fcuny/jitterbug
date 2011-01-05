
use strict;
use warnings;
use Test::More tests => 3;

use jitterbug::Builder;

{
    local @ARGV = qw(-c blarg.yml);
    my $b = jitterbug::Builder->new();

    isa_ok($b,'jitterbug::Builder');
    is($b->{'configfile'}, 'blarg.yml');
    can_ok($b,'run');
}
