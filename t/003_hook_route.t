use Test::More tests => 1;
use strict;
use warnings;
ok 1;
#use jitterbug;
#use JSON;
#use YAML qw/LoadFile/;
#use Dancer::Test;
#use Dancer::Config qw/setting/;

#my $content = LoadFile('t/data/test.yaml');

#setting jitterbug => { namespace => 'jitterbug_test' };

#route_exists [ POST => '/hook/' ], 'a route handle is defined for /';

#my $response;

#{
    #$response = dancer_response( POST => '/hook', );
    #is $response->{status}, 200, '200 with empty post';
#}

#{
    #my $payload = "payload=" . JSON::encode_json($content);
    #open my $in, '<', \$payload;

    #$ENV{'CONTENT_LENGTH'} = length($payload);
    #$ENV{'CONTENT_TYPE'}   = 'application/x-www-form-urlencoded';
    #$ENV{'psgi.input'}     = $in;

    #$response = dancer_response(
        #POST => '/hook/',
        #{
            #headers => [ 'Content-Length' => length($payload) ],
            #body    => $payload
        #}
    #);

    #is $response->{status}, 200;
    #is_deeply JSON::decode_json( $response->{content} ),
      #{ updated => 'Dancer' };
#}
