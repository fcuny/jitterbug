#!/bin/bash

# first arg:  build_dir
# second arg: report path

builddir=$1
report_path=$2

echo "Creating report_path=$report_path"
mkdir -p $report_path

cd $builddir

source $HOME/perl5/perlbrew/etc/bashrc

for perl in $HOME/perl5/perlbrew/perls/perl-5.*
do
    theperl="$(basename $perl)"

    echo ">perlbrew switch $theperl"
    perlbrew switch $theperl
    # TODO: check error condition

    perlversion=$(perl -v)
    logfile="$report_path/$theperl.txt"

    if [ -f 'dist.ini' ]; then
        echo "Found dist.ini, using Dist::Zilla"
        dzil authordeps | cpanm
        cpanm --installdeps .
        HARNESS_VERBOSE=1 dzil test >> $logfile  2>&1
    elif [ -f 'Build.PL' ]; then
        echo "Found Build.PL, using Build.PL"
        perl Build.PL
        # ./Build installdeps is not available in older Module::Build's
        cpanm --installdeps .
        HARNESS_VERBOSE=1 ./Build test --verbose >> $logfile 2>&1
    else
        echo "Hoping to find Makefile.PL"
        perl Makefile.PL
        cpanm --installdeps .
        make
        HARNESS_VERBOSE=1 make test >> $logfile 2>&1
    fi
done
