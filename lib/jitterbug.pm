package jitterbug;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use jitterbug::Plugin::Template;

our $VERSION = '0.1';

load_app 'jitterbug::Hook',       prefix => '/hook';
load_app 'jitterbug::Project',    prefix => '/project';
load_app 'jitterbug::WebService', prefix => '/api';
load_app 'jitterbug::Task',       prefix => '/task';

get '/' => sub {
    my $projects = _get_projects();
    my ( $builds, $runnings ) = _get_builds();

    template 'index',
      { projects => $projects, builds => $builds, runnings => $runnings };
};

sub _get_projects {

    my @projects = ();

    my $projects = schema->resultset('Project')->search();
    while ( my $project = $projects->next ) {
        my $owner     = from_json( $project->owner );
        my $proj_desc = {
            description => $project->description,
            name        => $project->name,
            url         => $project->url,
            owner_name  => $owner->{name},
        };

        my $last_commit =
          schema->resultset('Commit')
          ->search( { projectid => $project->projectid }, {order_by => {-desc => 'timestamp'}} )->first();

        if ($last_commit) {
            # XXX see what data to store here
            $proj_desc->{last_build} = from_json($last_commit->content);
        }

        push @projects, $proj_desc;
    }

    @projects =
      sort { $b->{last_build}->{timestamp} cmp $a->{last_build}->{timestamp} }
      @projects;

    return \@projects;
}

sub _get_builds {

    my @builds   = ();
    my @runnings = ();

    my $builds = schema->resultset('Task')->search();
    while ( my $build = $builds->next ) {
        my $build_desc = {
            project => $build->project->name,
            id      => $build->id,
            running => $build->running,
        };
        $build->running ? push @runnings, $build_desc : push @builds,
          $build_desc;
    }
    return ( \@builds, \@runnings );
}

true;
