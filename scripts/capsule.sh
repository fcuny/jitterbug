#!/bin/bash

set -e

builddir=$1
report_path=$2

mkdir -p $report_path

cd $builddir

source $HOME/perl5/perlbrew/etc/bashrc

for perl in $HOME/perl5/perlbrew/perls/perl-5.*
do
    theperl="$(basename $perl)"
    perlbrew switch $theperl
	hash -r

    perlversion=$(perl -v)
    logfile="$report_path/$theperl.txt"

    if [ -f 'dist.ini' ]
        dzil authordeps | cpanm
        cpanm --installdeps .
        HARNESS_VERBOSE=1 dzil test >> $logfile  2>&1
    else
        perl Makefile.PL
        cpanm --installdeps .
        make
        HARNESS_VERBOSE=1 make test >> $logfile  2>&1
    fi
done
