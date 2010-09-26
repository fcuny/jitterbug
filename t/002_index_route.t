use Test::More tests => 4;
use strict;
use warnings;

# the order is important
use jitterbug;
use Dancer::Test;
use Dancer::Config qw/setting/;

setting jitterbug => {namespace => 'jitterbug_test'};

route_exists          [ GET => '/' ], 'a route handler is defined for /';
response_status_is    [ GET => '/' ], 200, 'response status is 200 for /';
response_content_like [ GET => '/' ], qr/Dashboard/, 'content looks OK for /';
response_content_like [ GET => '/' ], qr/Repositories \(0\)/, 'no repositories';
