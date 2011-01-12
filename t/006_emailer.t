use strict;
use warnings;
use Test::Most tests => 3;
use Data::Dumper;
use Test::MockObject;

use_ok "jitterbug::Emailer";

{
    my $conf = { jitterbug => { build_process => 'bar'} };
    my $commit = Test::MockObject->new;
    my $project = Test::MockObject->new;
    my $task = Test::MockObject->new;

    $project->mock('name', sub { 'ponie' });

    $commit->mock('sha256', sub { 'c0decafe' });
    $commit->mock('content', sub { 'this should be JSON' } );

    $task->mock('commit', sub { $commit });
    $task->mock('project', sub { $project });

    my $tap = "1..1\nok 1\n";
    my $e = jitterbug::Emailer->new($conf, $task, $tap);

    isa_ok($e,'jitterbug::Emailer');
    can_ok($e,qw/new run/);

}
