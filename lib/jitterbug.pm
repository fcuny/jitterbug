package jitterbug;

#BEGIN {
    use Dancer ':syntax';
    use jitterbug::Plugin::Redis;
#};

our $VERSION = '0.1';

load_app 'jitterbug::Hook',       prefix => '/hook';
load_app 'jitterbug::Project',    prefix => '/project';
load_app 'jitterbug::WebService', prefix => '/api';

before_template sub {
    my $tokens = shift;
    $tokens->{uri_base} = request->base;
};

get '/' => sub {
    my @projects = redis->smembers(key_projects);
    template 'index', {projects => \@projects};
};

true;
