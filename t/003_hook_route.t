use Test::More tests => 11;
use strict;
use warnings;

use jitterbug;
use jitterbug::Schema;

use JSON;
use YAML qw/LoadFile Dump/;

use File::Spec;
use File::Temp qw/tempdir/;

use Dancer::Test;
use Dancer::Config qw/setting/;

my $content = LoadFile('t/data/test.yaml');

my $db_dir = tempdir( CLEANUP => 1 );
my $db_file = File::Spec->catfile( $db_dir, 'jitterbug.db' );
my $dsn     = 'dbi:SQLite:dbname=' . $db_file;
my $schema  = jitterbug::Schema->connect($dsn);
$schema->deploy;

setting plugins => {
    DBIC => {
        schema => {
            skip_automake => 1,
            pckg          => "jitterbug::Schema",
            connect_info  => [$dsn]
        }
    }
};

route_exists [ POST => '/hook/' ], 'a route handle is defined for /';

my $response;

{
    $response = dancer_response( POST => '/hook', );
    is $response->{status}, 200, '200 with empty post';
}

{
    my $rs = $schema->resultset('Project')->find( { name => 'Dancer' } );
    ok !defined $rs, 'no project dancer yet';

    $response = dancer_response(
        POST => '/hook/',
        {
            headers =>
              [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
            body => _generate_post_request($content),
        }
    );

    is $response->{status}, 200, 'status OK with payload';
    is_deeply JSON::decode_json( $response->{content} ),
      { updated => 'Dancer' }, 'response OK with payload';

    $rs = $schema->resultset('Project')->find( { name => 'Dancer' } );
    ok $rs, 'project exists in DB';
    is $rs->name, 'Dancer', 'project\'s name is good';

    is $schema->resultset('Task')->search()->count(), 1, 'one task created';
}

{
    $schema->resultset('Project')->search()->delete();
    $schema->resultset('Task')->search()->delete();

    # testing with invalid global branch
    setting jitterbug => { branches => { jt_global => ['foo'], }, };
    $content->{ref} = 'refs/heads/foo';
    $response = dancer_response(
        POST => '/hook/',
        {
            headers =>
              [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
            body => _generate_post_request($content),
        }
    );
    is $schema->resultset('Task')->search()->count(), 0, 'no task created since this branch is forbiden';
}

{
    $schema->resultset('Project')->search()->delete();
    $schema->resultset('Task')->search()->delete();

    # testing with invalid global branch
    setting jitterbug => { branches => { Dancer => ['foo'], }, };
    $content->{ref} = 'refs/heads/foo';
    $response = dancer_response(
        POST => '/hook/',
        {
            headers =>
              [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
            body => _generate_post_request($content),
        }
    );
    is $schema->resultset('Task')->search()->count(), 0, 'no task created since this branch is forbiden';
}

{
    $schema->resultset('Project')->search()->delete();
    $schema->resultset('Task')->search()->delete();

    # this branch is forbiden for another project
    setting jitterbug => { branches => { jitterbug => ['foo'], }, };
    $content->{ref} = 'refs/heads/foo';
    $response = dancer_response(
        POST => '/hook/',
        {
            headers =>
              [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
            body => _generate_post_request($content),
        }
    );
    is $schema->resultset('Task')->search()->count(), 1, 'one task created since this branch is authorized for this project';
}

sub _generate_post_request {
    my $content = shift;
    my $payload = "payload=" . JSON::encode_json($content);
    open my $in, '<', \$payload;

    $ENV{'CONTENT_LENGTH'} = length($payload);
    $ENV{'CONTENT_TYPE'}   = 'application/x-www-form-urlencoded';
    $ENV{'psgi.input'}     = $in;
    return $payload;
}
