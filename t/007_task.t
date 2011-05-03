use Test::More tests => 1;
use strict;
use warnings;

use lib 't/lib';

use jitterbug;
use jitterbug::Test;
use Dancer::Test;

jitterbug::Test->init();

response_status_is    [ GET => '/task/999' ], 404, "nonexistent task is a 404";
