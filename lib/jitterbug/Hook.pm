package jitterbug::Hook;

use Dancer ':syntax';
use jitterbug::Plugin::Redis;

setting serializer => 'JSON';

post '/' => sub {
    my $payload = params->{payload};

    if (!defined $payload) {
        # don't confuse poster, and don't care about it
        status 200;
        return;
    }

    $payload = from_json($payload);
    my $repo = $payload->{repository}->{name};

    my $repo_key = key_project($repo);

    if ( !redis->exists($repo_key) ) {
        my $project = {
            name        => $repo,
            url         => $payload->{repository}->{url},
            description => $payload->{repository}->{description},
            owner       => $payload->{repository}->{owner},
        };
        redis->set( $repo_key, to_json($project) );
        redis->sadd( key_projects, $repo );
    }

    my $last_commit = pop @{ $payload->{commits} };

    $last_commit->{repo}    = $payload->{repository}->{url};
    $last_commit->{project} = $repo;
    $last_commit->{compare} = $payload->{compare};

    my $task_key = key_task_repo($repo);
    redis->set( $task_key, to_json($last_commit) );

    redis->sadd( key_tasks, $task_key );

    { updated => $repo };
};

1;
