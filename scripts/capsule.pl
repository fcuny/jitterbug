#!/usr/bin/env perl

use strict;
use warnings;

my ($build_dir, $report_path, $perlbrew) = @ARGV;

my $logfile;

my $build_dispatch = {
    'dist.ini' => sub {
        print "Found dist.ini, using Dist::Zilla\n";
        my $cmd =<<CMD;
dzil authordeps | cpanm >> $logfile 2>&1
cpanm --installdeps . >> $logfile 2>&1
HARNESS_VERBOSE=1 dzil test >> $logfile  2>&1
CMD
    },
    'Build.PL' => sub {
        print "Found Build.PL, using Build.PL\n";
        my $cmd =<<CMD;
perl Build.PL >> $logfile 2>&1
# ./Build installdeps is not available in older Module::Build's
cpanm --installdeps . >> $logfile 2>&1
# Run this again in case our Build is out of date (suboptimal)
perl Build.PL >> $logfile 2>&1
HARNESS_VERBOSE=1 ./Build test --verbose >> $logfile 2>&1
CMD
    },
    'Makefile.PL' => sub {
        print "Found Makefile.PL\n";
        my $cmd =<<CMD;
perl Makefile.PL >> $logfile 2>&1
cpanm --installdeps . >> $logfile 2>&1
HARNESS_VERBOSE=1 make test >> $logfile 2>&1
CMD
    },
    'setup.pir' => sub {
        print "Found setup.pir\n";
        my $cmd =<<CMD;
HARNESS_VERBOSE=1 parrot setup.pir test >> $logfile 2>&1
CMD
    },
    'setup.nqp' => sub {
        print "Found setup.nqp\n";
        my $cmd =<<CMD;
HARNESS_VERBOSE=1 parrot-nqp setup.nqp test >> $logfile 2>&1
CMD
    },
    'Configure.pl' => sub {
        print "Found Configure.pl\n";
        my $cmd =<<CMD;
perl Configure.pl >> $logfile 2>&1
cpanm --installdeps . >> $logfile 2>&1
HARNESS_VERBOSE=1 make test >> $logfile 2>&1
CMD
    },
    'Makefile' => sub {
        print "Found a Makefile\n";
        my $cmd =<<CMD;
make test >> $logfile 2>&1
CMD
    },
    'Rakefile' => sub {
        print "Found a Rakefile\n";
        my $cmd =<<CMD;
rake test >> $logfile 2>&1
CMD
    },
};
