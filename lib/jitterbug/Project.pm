package jitterbug::Project;

use Dancer ':syntax';
use jitterbug::Plugin::Redis;
use jitterbug::Plugin::Template;

use DateTime;
use XML::Feed;

get '/:project' => sub {
    my $project = params->{project};

    my $res = redis->get( key_project($project) );

    send_error( "Project $project not found", 404 ) if !$res;

    my $desc = from_json($res);

    my $builds = _sorted_builds($project);

    my $commits;
    foreach (@$builds) {
        my $t = $_->{timestamp};
        (my $d) = $t =~ /^(\d{4}-\d{2}-\d{2})/;
        push @{$commits->{$d}}, $_;
    }

    my @days = sort {$b cmp $a} keys %$commits;

    template 'project/index',
      { project => $project, days => \@days, builds => $commits, %$desc };
};

get '/:project/feed' => sub {
    my $project = params->{project};

    my $builds = _sorted_builds($project);

    my $feed = XML::Feed->new('Atom');
    $feed->title('builds for '.$project);

    foreach my $build (@$builds) {
        foreach my $version (keys %{$build->{version}}) {
            my $entry = XML::Feed::Entry->new();
            $entry->link( request->base
                  . 'api/build/'
                  . $project . '/'
                  . $build->{commit} . '/'
                  .$version );
            $entry->title( "build for " . $build->{commit} . ' on ' . $version );
            $entry->summary( "Result: " . $build->{version}->{$version} );
            $feed->add_entry($entry);
        }
    }

    content_type('application/atom+xml');
    $feed->as_xml;
};

sub _sorted_builds {
    my $project = shift;

    my @ids = redis->smembers( key_builds_project($project) );

    my @builds;
    foreach my $id (@ids) {
        my $res = redis->get($id);
        push @builds, from_json($res) if $res;
    }
    @builds = sort {$b->{timestamp} cmp $a->{timestamp}} @builds;
    \@builds;
}

1;
