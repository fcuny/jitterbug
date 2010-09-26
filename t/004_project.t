use Test::More tests => 1;
use strict;
use warnings;

use jitterbug;
use Dancer::Test;
use Dancer::Config qw/setting/;

setting jitterbug => {namespace => 'jitterbug_test'};

my $response;

{
    $response = dancer_response(GET => '/project/Dancer');
    is $response->{status}, 200;
}
