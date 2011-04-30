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
};
