package jitterbug::Hook;

BEGIN {
    use Dancer ':syntax';
    load_plugin 'jitterbug::Plugin::Redis';
};

setting serializer => 'JSON';

post '/' => sub {
    my $hook = from_json(params->{payload});

    my $repo = $hook->{repository}->{name};

    my $repo_key = key_project($repo);

    if ( !redis->exists($repo_key) ) {
        my $project = {
            name        => $repo,
            url         => $hook->{repository}->{url},
            description => $hook->{repository}->{description},
            owner       => $hook->{repository}->{owner},
        };
        redis->set( $repo_key, to_json($project) );
        redis->sadd(key_projects, $repo);
    }

    my $last_commit = pop @{ $hook->{commits} };

    $last_commit->{repo}    = $hook->{repository}->{url};
    $last_commit->{project} = $repo;
    $last_commit->{compare} = $hook->{compare};

    my $task_key = key_task_repo($repo);
    redis->set($task_key, to_json($last_commit));

    redis->sadd(key_tasks, $task_key);

    { updated => $repo };
};

1;
