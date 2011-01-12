use strict;
use warnings;
use Test::Most tests => 8;
use Data::Dumper;
use Test::MockObject;

use_ok "jitterbug::Emailer";

{
    my $buildconf = {
        on_failure_from_email     => 'bob@example.com',
        on_failure_cc_email       => 'steve@apple.com',
        on_failure_subject_prefix => 'BLARG ',
    };

    my $conf    = { jitterbug => { build_process => $buildconf } };
    my $commit  = Test::MockObject->new;
    my $project = Test::MockObject->new;
    my $task    = Test::MockObject->new;

    $project->mock('name', sub { 'ponie' });

    $commit->mock('sha256', sub { 'c0decafe' });
    $commit->mock('content', sub { '{  }' } );

    $task->mock('commit', sub { $commit });
    $task->mock('project', sub { $project });

    my $tap = "THIS IS TAP";
    my $e = jitterbug::Emailer->new($conf, $task, $tap);

    isa_ok($e,'jitterbug::Emailer');
    can_ok($e,qw/new run/);

    $e->run;
    my $email = $e->{'last_email_sent'}{'email'};
    like($email->body, qr/THIS IS TAP/, 'email body looks right');

    my $header = $email->{'header'};
    isa_ok($header, 'Email::MIME::Header');

    is($header->header_raw('cc'), 'steve@apple.com', 'cc header');
    is($header->header_raw('subject'), 'BLARG ponie @ c0decafe', 'subject header');
    is($header->header_raw('from'), 'bob@example.com', 'from header');

}
