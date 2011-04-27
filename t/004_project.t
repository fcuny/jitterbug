use Test::More tests => 1;
use strict;
use warnings;

use lib 't/lib';

use jitterbug;
use jitterbug::Test;
use Dancer::Test;

jitterbug::Test->init();

my $r;

{
    local $TODO = "non-existent project gives a 500 instead of a 404";
    $r = dancer_response(GET => '/project/Dancer');
    is $r->status, 404 or diag $r->content;
}
