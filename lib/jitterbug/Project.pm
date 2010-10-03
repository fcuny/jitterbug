package jitterbug::Project;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use jitterbug::Plugin::Template;

use Digest::MD5 qw/md5_hex/;
use DateTime;
use XML::Feed;

get '/:project' => sub {
    my $project =
      schema->resultset('Project')->find( { name => params->{project} } );

    send_error( "Project " . params->{project} . " not found", 404 )
      unless $project;

    my $builds = _sorted_builds($project);

    my $commits;
    foreach (@$builds) {
        $_->{avatar} = md5_hex( lc( $_->{author}->{email} ) );
        my $t = $_->{timestamp};
        (my $d) = $t =~ /^(\d{4}-\d{2}-\d{2})/;
        push @{$commits->{$d}}, $_;
    }

    my @days = sort {$b cmp $a} keys %$commits;

    template 'project/index',
        {project => $project, days => \@days, commits => $commits};
};

get '/:project/feed' => sub {
    my $project =
      schema->resultset('Project')->find( { name => params->{project} } );

    send_error( "Project " . params->{project} . " not found", 404 )
      unless $project;

    my $builds = _sorted_builds($project);

    my $feed = XML::Feed->new('Atom');
    $feed->title('builds for '.$project->name);

    foreach my $build (@$builds) {
        foreach my $version (keys %{$build->{version}}) {
            my $entry = XML::Feed::Entry->new();
            $entry->link( request->base
                  . 'api/build/'
                  . $project . '/'
                  . $build->{commit} . '/'
                  .$version );
            $entry->author($build->{author}->{name});
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

    my $commits =
      schema->resultset('Commit')
      ->search( { projectid => $project->projectid } );

    my @builds;
    while ( my $c = $commits->next ) {
        my $content = from_json($c->content);
        $content->{id} = $c->sha256 if (!$content->{id});
        push @builds, $content;
    }

    @builds = sort { $b->{timestamp} cmp $a->{timestamp} } @builds;
    \@builds;
}

1;
