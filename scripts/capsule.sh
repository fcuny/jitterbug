#!/bin/bash

# first arg:  build_dir
# second arg: report path
# third arg: should we use perlbrew?

# this is getting smelly
builddir=$1
report_path=$2
perlbrew=$3

function jitterbug_build () {
    if [ -f 'dist.ini' ]; then
        echo "Found dist.ini, using Dist::Zilla"
        dzil authordeps | cpanm >> $logfile 2>&1
        cpanm --installdeps . >> $logfile 2>&1
        HARNESS_VERBOSE=1 dzil test >> $logfile  2>&1
    elif [ -f 'Build.PL' ]; then
        echo "Found Build.PL, using Build.PL"
        perl Build.PL >> $logfile 2>&1
        # ./Build installdeps is not available in older Module::Build's
        cpanm --installdeps . >> $logfile 2>&1
        # Run this again in case our Build is out of date (suboptimal)
        perl Build.PL >> $logfile 2>&1
        HARNESS_VERBOSE=1 ./Build test --verbose >> $logfile 2>&1
    elif [ -f 'Makefile.PL' ]; then
        echo "Found Makefile.PL"
        perl Makefile.PL >> $logfile 2>&1
        cpanm --installdeps . >> $logfile 2>&1
        HARNESS_VERBOSE=1 make test >> $logfile 2>&1
    elif [ -f 'setup.pir' ]; then
        echo "Found setup.pir"
        HARNESS_VERBOSE=1 parrot setup.pir test >> $logfile 2>&1
    elif [ -f 'setup.nqp' ]; then
        echo "Found setup.nqp"
        HARNESS_VERBOSE=1 parrot-nqp setup.nqp test >> $logfile 2>&1
    elif [ -f 'Configure.pl' ]; then
        echo "Found Configure.pl"
        perl Configure.pl >> $logfile 2>&1
        cpanm --installdeps . >> $logfile 2>&1
        HARNESS_VERBOSE=1 make test >> $logfile 2>&1
    elif [ -f 'Makefile' ]; then
        echo "Found a Makefile"
        make test >> $logfile 2>&1
    elif [ -f 'Rakefile' ]; then
        rake test >> $logfile 2>&1
    fi
}


echo "Creating report_path=$report_path"
mkdir -p $report_path

cd $builddir

if [ $use_perlbrew ]; then
    source $HOME/perl5/perlbrew/etc/bashrc
    for perl in $HOME/perl5/perlbrew/perls/perl-5.*
    do
        theperl=$(perl -e 'print $^V')
        logfile="$report_path/perl-$theperl.txt"

        echo ">perlbrew switch $theperl"
        perlbrew switch $theperl
        # TODO: check error condition

        jitterbug_build
    done
else
        theperl=$(perl -e 'print $^V')
        logfile="$report_path/perl-$theperl.txt"
        jitterbug_build
fi
