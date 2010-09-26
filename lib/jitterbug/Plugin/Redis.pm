package jitterbug::Plugin::Redis;

use Dancer::Config qw/setting/;
use Dancer::Plugin;
use Redis;

register redis => sub {
    Redis->new( server => setting('redis') );
};

sub _key {
    my $s = setting('jitterbug');
    my $ns = $s->{namespace} || 'jitterbug';
    join( ':', $ns, @_ );
}

register key_projects       => sub { _key('projects'); };
register key_project        => sub { _key('project', @_); };
register key_builds_project => sub { _key('builds', @_); };
register key_task_repo      => sub { _key('tasks', @_); };
register key_tasks          => sub { _key('tasks'); };

register_plugin;

1;
