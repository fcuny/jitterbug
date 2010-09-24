package jitterbug::WebService;

use Dancer ':syntax';
use jitterbug::Plugin::Redis;

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
        {
            commit  => $commit,
            version => $version,
            content => join( '', @content ),
        };
    }
};

1;
