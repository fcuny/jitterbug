package jitterbug::Hook;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;

use Try::Tiny;

setting serializer => 'JSON';

post '/' => sub {
    my $payload = params->{payload};

    # don't confuse poster, and don't care about it
    if (!defined $payload) {
        error("no payload in input");
        status 200;
        return;
    }

    $payload = from_json($payload);
    my $repo = $payload->{repository}->{name};
    my $ref  = $payload->{ref};

    my $authorized = _authorized_branch( $repo, $ref );
    if ( !$authorized ) {
        debug("this branch is not authorized");
        status 200;
        return;
    }

    my $project = schema->resultset('Project')->find( { name => $repo } );

    $project = _create_new_project($repo, $payload) if !$project;

    my $last_commit = pop @{ $payload->{commits} };
    $last_commit->{compare} = $payload->{compare};
    $last_commit->{pusher}  = $payload->{pushed};
    $last_commit->{ref}     = $payload->{ref};

    _insert_commit($last_commit, $project);
    _insert_new_task( $last_commit, $project );

    debug("hook accepted");

    { updated => $repo };
};

sub _authorized_branch {
    my ($repo, $ref) = @_;
    my $jtbg_conf     = setting 'jitterbug';
    my $branches_conf = $jtbg_conf->{branches};

    foreach my $name ($repo, 'jt_global') {
        if ( defined $branches_conf->{$name} ) {
            return 0 if _should_skip( $ref, $branches_conf->{$name} );
        }
    }
    return 1;
}

sub _should_skip {
    my ( $ref, $conf ) = @_;
    foreach my $br_name (@$conf) {
        return 1 if $ref =~ m!^refs/heads/$br_name!;
    }
    return 0;
}

sub _create_new_project {
    my ($repo, $payload) = @_;

    debug("need to create a new project");

    my $project;
    try {
        schema->txn_do(
            sub {
                $project = schema->resultset('Project')->create(
                    {
                        name        => $repo,
                        url         => $payload->{repository}->{url},
                        description => $payload->{repository}->{description},
                        owner => to_json( $payload->{repository}->{owner} ),
                    }
                );
            }
        );
    }
    catch {
        error($_);
    };
    return $project;
}

sub _insert_commit {
    my ($commit, $project) = @_;

    try {
        schema->txn_do(
            sub {
                schema->resultset('Commit')->create(
                    {
                        sha256    => $commit->{id},
                        content   => to_json($commit),
                        projectid => $project->projectid,
                        timestamp => $commit->{timestamp},
                    }
                );
            }
        );
    }
    catch {
        error($_);
    };
}

sub _insert_new_task {
    my ( $commit, $project ) = @_;
    try {
        schema->txn_do(
            sub {
                schema->resultset('Task')->create(
                    {
                        sha256    => $commit->{id},
                        projectid => $project->projectid
                    }
                );
            }
        );
    }
    catch {
        error($_);
    };
}

1;
