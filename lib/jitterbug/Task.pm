package jitterbug::Task;

use Dancer ':syntax';
use jitterbug::Plugin::Redis;
use jitterbug::Plugin::Template;

get '/:task_id' => sub {
    my $task_id = params->{task_id};

    my $task = redis->get($task_id);

    if (!$task) {
        render_error("task doesn't exists", 404);
    }

    template 'task/index', {task => from_json($task)};
};

1;
