
use strict;
use warnings;
use Test::Most tests => 9;
use Data::Dumper;

use jitterbug::Builder;

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
                                              },
                             'builder' => {},
                             'reports' => {
                                          'dir' => '/tmp/jitterbug'
                                        },
                             'build' => {
                                        'dir' => '/tmp/build'
                                      }
                           },
            'template' => 'xslate',
            'appname' => 'jitterbug',
            'layout' => 'main',
            'logger' => 'file',
            'builds_per_feed' => '5'
    });


}

