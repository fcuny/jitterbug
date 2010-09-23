#!/bin/sh -e

gitrepo=$1
project=$2
commit=$3

ORIGIN=$(pwd)
BUILDDIR=$(mktemp -d)
LOGDIR="/tmp/jitterbug"
mkdir -p $LOGDIR
logfile="$LOGDIR/$project.$commit.txt"
cd $BUILDDIR
rm -rf $project
git clone $gitrepo $project
cd $project
git checkout $commit
perl Makefile.PL
make
make test 2>&1 > $logfile
cd ..
rm -rf $BUILDDIR
