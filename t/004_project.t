use Test::More tests => 1;
use strict;
use warnings;

use lib 't/lib';

use jitterbug;
use jitterbug::Test;
use Dancer::Test;

jitterbug::Test->init();

my $response;

{
    $response = dancer_response(GET => '/project/Dancer');
    is $response->status, 404;
}
