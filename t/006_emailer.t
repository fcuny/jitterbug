use strict;
use warnings;
use Test::Most tests => 3;
use Data::Dumper;

use_ok "jitterbug::Emailer";

{
    my $conf = { foo => 'bar' };
    my $task = {};
    my $tap = "1..1\nok 1\n";
    my $e = jitterbug::Emailer->new($conf, $task, $tap);

    isa_ok($e,'jitterbug::Emailer');
    can_ok($e,qw/new run/);

}
