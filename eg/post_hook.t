use strict;
use warnings;
use 5.010;
use LWP::UserAgent;
use HTTP::Request::Common;
use YAML qw/LoadFile/;
use JSON;

my $content = LoadFile('t/data/test.yaml');
my $payload = JSON::encode_json($content);

my $url = "http://localhost:5000/hook/";

my $req = POST $url, [payload => $payload];

my $ua = LWP::UserAgent->new();
my $res = $ua->request($req);
$res->is_success ? say "ok" : say "not ok";
