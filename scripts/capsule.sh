#!/bin/bash

set -e

builddir=$1
report_path=$2

mkdir -p $report_path

cd $builddir

source $HOME/perl5/perlbrew/etc/bashrc

for perl in $HOME/perl5/perlbrew/perls/perl-5.12.*
do
    theperl="$(basename $perl)"
    perlbrew switch $theperl
	hash -r

    perlversion=$(perl -v)
    logfile="$report_path/$theperl.txt"

    perl Makefile.PL
    make
    HARNESS_VERBOSE=1 make test >> $logfile  2>&1
done
