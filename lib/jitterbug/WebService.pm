package jitterbug::WebService;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;

use File::Spec;

set serializer => 'JSON';

get '/build/:project/:commit/:version' => sub {
    my $project = params->{project};
    my $commit  = params->{commit};
    my $version = params->{version};

    my $conf = setting 'jitterbug';

    my $file = File::Spec->catfile( $conf->{reports}->{dir},
        $project, $commit, $version . '.txt' );

    if ( -f $file ) {
        open my $fh, '<', $file;
        my @content = <$fh>;
        close $fh;

        if ( request->accept =~ m!application/json! ) {
            return {
                commit  => $commit,
                version => $version,
                content => join( '', @content ),
            };
        }
        else {
            content_type 'text/plain';
            return join( '', @content );
        }
    }
};

del '/task/:id' => sub {
    my $id = params->{id};

    my $task = schema->resultset('Task')->find({sha256 => $id});

    if (!$task){
        send_error("Can't find task for $id", 404);
        return;
    }

    $task->delete;
    status(201);
    {status => "task $id deleted"};
};

1;
