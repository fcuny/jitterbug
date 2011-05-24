use Test::More tests => 5;
use strict;
use warnings;

use lib 't/lib';

use jitterbug;
use jitterbug::Test;
use Dancer::Test;

jitterbug::Test->init();

route_exists          [ GET => '/' ], 'a route handler is defined for /';
response_status_is    [ GET => '/' ], 200, 'response status is 200 for /';
response_content_like [ GET => '/' ], qr/Dashboard/, 'content looks OK for /';
response_content_like [ GET => '/' ], qr/Repositories \(\d+\)/, 'repositories';
response_content_like [ GET => '/' ], qr/Builds pending \(\d+\)/, 'pending builds';
