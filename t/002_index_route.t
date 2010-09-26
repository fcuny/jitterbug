use Test::More tests => 3;
use strict;
use warnings;

# the order is important
use jitterbug;
use Dancer::Test;

route_exists [GET => '/'], 'a route handler is defined for /';
response_status_is ['GET' => '/'], 200, 'response status is 200 for /';
response_content_like [GET => '/'], qr/Dashboard/, 'content looks OK for /';
