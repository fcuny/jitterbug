use strict;
use warnings;
use Test::Most tests => 9;
use Data::Dumper;
use Test::MockObject;

use_ok "jitterbug::Emailer";

sub setup {
    my $buildconf = {
        on_failure_from_email     => 'bob@example.com',
        on_failure_cc_email       => 'steve@apple.com',
        on_failure_subject_prefix => 'BLARG ',
        on_failure_header         => "Summary:\n%%SUMMARY%%",
        on_failure_footer         => "FOOT",
    };

    my $conf    = { jitterbug => { build_process => $buildconf } };
    my $commit  = Test::MockObject->new;
    my $project = Test::MockObject->new;
    my $task    = Test::MockObject->new;

    $project->mock('name', sub { 'ponie' });

    $commit->mock('sha256', sub { 'c0decafe' });
    $commit->mock('content', sub { '{ "message" : "blargly blarg"  }' } );

    $task->mock('commit', sub { $commit });
    $task->mock('project', sub { $project });
    return ($conf, $commit, $project, $task);
}

{
    my ($conf, $commit, $project, $task) = setup();
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
    like($header->header_raw('subject'), qr/BLARG ponie @ c0decafe blargly blarg/, 'subject header');
    is($header->header_raw('from'), 'bob@example.com', 'from header');
}

{
    my ($conf, $commit, $project, $task) = setup();
    my $tap = <<TAP;
Copying lib/Math/Primality/AKS.pm -> blib/lib/Math/Primality/AKS.pm
Copying lib/Math/Primality/BigPolynomial.pm -> blib/lib/Math/Primality/BigPolynomial.pm
Copying lib/Math/Primality.pm -> blib/lib/Math/Primality.pm
Copying bin/primes.pl -> blib/script/primes.pl
Copying bin/strong_psuedoprimes.pl -> blib/script/strong_psuedoprimes.pl
# Testing Math::Primality 0.0401, Perl 5.010001, /usr/bin/perl
t/00-load.t ......................
1..1
ok 1 - use Math::Primality;
ok
#   Failed test '-1 is not prime'
#   at t/is_prime.t line 16.
# Looks like you failed 1 test of 573.
t/is_prime.t .....................
1..6
ok 1 - is_prime should handle Math::GMPz objects, three is prime
ok 2 - 2 is prime
ok 3 - 1 is not prime
ok 4 - 0 is not prime
not ok 5 - -1 is not prime
ok 6 - blarg
t/boilerplate.t ..................
1..3
ok 1 - README contains no boilerplate text
ok 2 - Changes contains no boilerplate text
ok 3 - lib/Math/Primality.pm contains no boilerplate text
ok
Test Summary Report
-------------------
t/is_prime.t                   (Wstat: 256 Tests: 573 Failed: 1)
Failed test:  5
Non-zero exit status: 1
Failed 1/11 test programs. 1/2498 subtests failed.
Files=11, Tests=2498,  3 wallclock secs ( 0.20 usr  0.04 sys +  2.99 cusr  0.18 csys =  3.41 CPU)
Result: FAIL
TAP
    my $e = jitterbug::Emailer->new($conf, $task, $tap);
    $e->run;
    my $email = $e->{'last_email_sent'}{'email'};
    my $body = <<EMAIL;
Summary:
Test Summary Report
-------------------
t/is_prime.t                   (Wstat: 256 Tests: 573 Failed: 1)
Failed test:  5
Non-zero exit status: 1
Failed 1/11 test programs. 1/2498 subtests failed.
Files=11, Tests=2498,  3 wallclock secs ( 0.20 usr  0.04 sys +  2.99 cusr  0.18 csys =  3.41 CPU)
Result: FAIL

Commit Message:
blargly blarg

TAP Output:
Copying lib/Math/Primality/AKS.pm -> blib/lib/Math/Primality/AKS.pm
Copying lib/Math/Primality/BigPolynomial.pm -> blib/lib/Math/Primality/BigPolynomial.pm
Copying lib/Math/Primality.pm -> blib/lib/Math/Primality.pm
Copying bin/primes.pl -> blib/script/primes.pl
Copying bin/strong_psuedoprimes.pl -> blib/script/strong_psuedoprimes.pl
# Testing Math::Primality 0.0401, Perl 5.010001, /usr/bin/perl
t/00-load.t ......................
1..1
ok 1 - use Math::Primality;
ok
#   Failed test '-1 is not prime'
#   at t/is_prime.t line 16.
# Looks like you failed 1 test of 573.
t/is_prime.t .....................
1..6
ok 1 - is_prime should handle Math::GMPz objects, three is prime
ok 2 - 2 is prime
ok 3 - 1 is not prime
ok 4 - 0 is not prime
not ok 5 - -1 is not prime
ok 6 - blarg
t/boilerplate.t ..................
1..3
ok 1 - README contains no boilerplate text
ok 2 - Changes contains no boilerplate text
ok 3 - lib/Math/Primality.pm contains no boilerplate text
ok
Test Summary Report
-------------------
t/is_prime.t                   (Wstat: 256 Tests: 573 Failed: 1)
Failed test:  5
Non-zero exit status: 1
Failed 1/11 test programs. 1/2498 subtests failed.
Files=11, Tests=2498,  3 wallclock secs ( 0.20 usr  0.04 sys +  2.99 cusr  0.18 csys =  3.41 CPU)
Result: FAIL

FOOT
EMAIL

    my $ebody = $email->body;
    $ebody =~ s/\r\n/\n/g;
    eq_or_diff($ebody, $body, 'email body has failure summary');

}
