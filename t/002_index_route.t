use Test::More tests => 4;
use strict;
use warnings;

use jitterbug;
use jitterbug::Schema;

use Dancer::Test;
use Dancer::Config qw/setting/;

use YAML qw/LoadFile/;
use File::Spec;
use File::Temp qw/tempdir/;

my $content = LoadFile('t/data/test.yaml');

my $db_dir = tempdir( CLEANUP => 1 );
my $db_file = File::Spec->catfile( $db_dir, 'jitterbug.db' );
my $dsn     = 'dbi:SQLite:dbname=' . $db_file;
my $schema  = jitterbug::Schema->connect($dsn);
$schema->deploy;

setting layout   => 'main';
setting template => "xslate";
setting views    => 'views';
setting engines  => {
    xslate => {
        path  => '/',
        type  => 'text',
        cache => 0,
    }
};

setting plugins => {
    DBIC => {
        schema => {
            skip_automake => 1,
            pckg          => "jitterbug::Schema",
            connect_info  => [$dsn]
        }
    }
};

route_exists          [ GET => '/' ], 'a route handler is defined for /';
response_status_is    [ GET => '/' ], 200, 'response status is 200 for /';
response_content_like [ GET => '/' ], qr/Dashboard/, 'content looks OK for /';
response_content_like [ GET => '/' ], qr/Repositories \(0\)/, 'no repositories';
