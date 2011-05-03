package jitterbug::Task;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use jitterbug::Plugin::Template;

get '/:task_id' => sub {
    my $task_id = params->{task_id};

    my $task = schema->resultset('Task')->find($task_id);

    if (!$task) {
        send_error("task does not exist!", 404);
    }

    template 'task/index', {task => $task };
};

1;
