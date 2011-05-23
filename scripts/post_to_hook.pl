use strict;
use warnings;

use jitterbug;
use jitterbug::Schema;

use JSON;
use YAML qw/LoadFile Dump/;

use File::Temp qw/tempdir/;

use Dancer::Test;
use Dancer::Config qw/setting/;
use File::Spec::Functions;

my $content = LoadFile(shift || catfile(qw/t data hook_data.yml/));

my $db_file = catfile( qw/t data jitterbug.db/ );
my $dsn     = 'dbi:SQLite:dbname=' . $db_file;
my $schema  = jitterbug::Schema->connect($dsn);
# assume we have a deployed schema
# $schema->deploy;

setting plugins => {
    DBIC => {
        schema => {
            skip_automake => 1,
            pckg          => "jitterbug::Schema",
            connect_info  => [$dsn]
        }
    }
};

{
    my $response = dancer_response(
        POST => '/hook/',
        {
            headers =>
              [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
            body => _generate_post_request($content),
        }
    );

    printf "Response was: %s\n",  $response->{status};
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

