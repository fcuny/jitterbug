package jitterbug::Project;

BEGIN {
    use Dancer ':syntax';
    load_plugin 'jitterbug::Plugin::Redis';
};

use DateTime;
use XML::Feed;

get '/:project' => sub {
    my $project = params->{project};

    my $res = redis->get( key_project($project) );

    send_error( "Project $project not found", 404 ) if !$res;

    my $desc = from_json($res);

    my @ids = redis->smembers( key_builds_project($project) );

    my @builds;
    foreach my $id (@ids) {
        my $res = redis->get($id);
        push @builds, from_json($res) if $res;
    }

    template 'project/index',
      { project => $project, builds => \@builds, %$desc };
};

get '/:project/feed' => sub {
    my $project = params->{project};

    my @builds = reverse( redis->smembers( key_builds_project($project) ) );

    my $feed = XML::Feed->new('Atom');
    $feed->title('builds for '.$project);

    foreach (splice(@builds, 0, 5)) {
        my $res = redis->get($_);
        next unless $res;
        my $desc = from_json($res);

        foreach my $version (keys %{$desc->{version}}) {
            my $entry = XML::Feed::Entry->new();
            $entry->title("build for ".$desc->{commit}.' on '.$version);
            $entry->summary("Result: ".$desc->{version}->{$version});
            $feed->add_entry($entry);
        }
    }

    content_type('application/atom+xml');
    $feed->as_xml;
};

1;
