
use strict;
use warnings;
use Test::Most tests => 9;
use Data::Dumper;

use lib 't/lib';
use jitterbug::Test;
use jitterbug::Builder;

jitterbug::Test->init();

{
    local @ARGV = qw(-c t/data/test.yml -C);
    my $b = jitterbug::Builder->new();

    isa_ok($b,'jitterbug::Builder');
    can_ok($b,qw/run build run_task sleep/);

    is($b->{'configfile'}, 't/data/test.yml');
    is($b->{'cron'}, 1 );
}

{
    local @ARGV = qw(-c blarg.yml -C);

    throws_ok (sub {
        my $b = jitterbug::Builder->new();
    }, qr/Does not exist/i, 'nonexistent yaml file throws error');
}

{
    local @ARGV = qw(-c t/data/test.yml -C);
    my $b = jitterbug::Builder->new();
    isa_ok($b, 'jitterbug::Builder');
    is($b->{'configfile'}, 't/data/test.yml');

    is($b->run, 0, '->run returns 0 in cron mode');

    cmp_deeply($b->{'conf'}, {
            'engines' => {
                         'xslate' => {
                                     'type' => 'text',
                                     'path' => '/',
                                     'cache' => '0'
                                   }
                       },
            'plugins' => {
                           'DBIC' => {
                                       'schema' => {
                                                   'connect_info' => [
                                                                       'dbi:SQLite:dbname=t/data/jitterbug.db'
                                                                     ],
                                                   'pckg' => 'jitterbug::Schema',
                                                   'skip_automake' => '1'
                                                 }
                                     }
                         },
            'jitterbug' => {
                             'build_process' => {
                                                'on_failure' => './scripts/build-failed.sh',
                                                'builder' => './scripts/capsule.sh',
                                                'builder_variables' => 'STUFF=BLAH',
                                                'on_pass_header' => undef,
                                                'on_failure_subject_prefix' => '[jitterbug] FAIL ',
                                                'on_failure_from_email' => 'donotreply@example.com',
                                                'on_failure_footer' => undef,
                                                'on_failure_header' => undef,
                                                'on_pass_footer' => undef,
                                                'on_pass_cc_email' => 'alice@example.com',
                                                'on_pass_from_email' => 'donotreply@example.com',
                                                'on_failure_cc_email' => 'alice@example.com',
                                                'on_pass' => './scripts/build-pass.sh',
                                                'on_pass_subject_prefix' => '[jitterbug] PASS '
                                              },
                             'builder' => {},
                             'reports' => {
                                          'dir' => '/tmp/jitterbug'
                                        },
                             'build' => {
                                        'dir' => '/tmp/build'
                                      },
                             'options' => {
                                        'email_on_pass' => '0',
                                        'perlbrew' => '1'
                                      },

                           },
            'template' => 'xslate',
            'appname' => 'jitterbug',
            'layout' => 'main',
            'logger' => 'file',
            'builds_per_feed' => '5'

    });


}

