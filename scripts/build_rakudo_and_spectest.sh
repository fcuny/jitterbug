#!/bin/sh

# This serves as an example of a custom build script, which builds
# Rakudo Perl 6 and times a spectest run

make realclean
perl Configure.pl --gen-parrot
make
make t/spec
time make spectest
