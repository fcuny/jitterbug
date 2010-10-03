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

    my $project = schema->resultset('Project')->find( { name => $repo } );

    if ( !$project ) {
        debug("need to create a new project");
        try {
            schema->txn_do(
                sub {
                    $project = schema->resultset('Project')->create(
                        {
                            name => $repo,
                            url  => $payload->{repository}->{url},
                            description =>
                              $payload->{repository}->{description},
                            owner => to_json($payload->{repository}->{owner}),
                        }
                    );
                }
            );
        }
        catch {
            error($_);
        };
    }

    my $last_commit = pop @{ $payload->{commits} };
    $last_commit->{compare} = $payload->{compare};
    $last_commit->{pusher}  = $payload->{pushed};
    $last_commit->{ref}     = $payload->{ref};

    try {
        schema->txn_do(
            sub {
                schema->resultset('Commit')->create(
                    {
                        sha256    => $last_commit->{id},
                        content   => to_json($last_commit),
                        projectid => $project->projectid,
                        timestamp => $last_commit->{timestamp},
                    }
                );
            }
        );
    }
    catch {
        debug($_);
    };

    try {
        schema->txn_do(
            sub {
                schema->resultset('Task')->create(
                    {sha256 => $last_commit->{id}, projectid => $project->projectid}
                );
            }
        );
    }catch{
        debug($_);
    };

    debug("hook accepted");

    { updated => $repo };
};

1;
