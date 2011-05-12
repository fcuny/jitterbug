package jitterbug::Task;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use jitterbug::Plugin::Template;

get '/:id' => sub {
    my $task = schema->resultset('Task')->find( params->{id} );


    if ( !defined $task ) {
        send_error("task does not exist!", 404);
        return;
    }

    my $commit = from_json( $task->commit->content );

    template 'task/index',
      {
        task   => { id => $task->id, started_when => $task->started_when },
        commit => $commit
      };
};

1;
