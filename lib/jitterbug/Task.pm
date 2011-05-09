package jitterbug::Task;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use jitterbug::Plugin::Template;

get '/:task_id' => sub {
    my $task_id = params->{task_id};

    my $task = schema->resultset('Task')->find($task_id);
    my $commit =
      schema->resultset('Commit')->find( { sha256 => $task->sha256 } );

    if (!$task) {
        send_error("task does not exist!", 404);
    }

    if (!$commit){
        render_error("commit doesn't exists", 404);
    }

    my $content = from_json($commit->content);
    template 'task/index', {task => $task, commit => $content };
};

1;
