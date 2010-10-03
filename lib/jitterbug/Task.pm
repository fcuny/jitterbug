package jitterbug::Task;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use jitterbug::Plugin::Template;

get '/:task_id' => sub {
    my $task_id = params->{task_id};

    my $task = schema->resultset('Task')->search($task_id);

    if (!$task) {
        render_error("task doesn't exists", 404);
    }

    template 'task/index', {task => $task };
};

1;
