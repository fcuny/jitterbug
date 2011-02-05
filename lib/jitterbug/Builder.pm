package jitterbug::Builder;

use strict;
use warnings;

use YAML qw/LoadFile Dump/;
use JSON;
use File::Path qw/rmtree/;
use Path::Class;
use Getopt::Long qw/:config no_ignore_case/;
use File::Basename;
use Git::Repository;
use jitterbug::Schema;
use Cwd;
#use Data::Dumper;

local $| = 1;
use constant DEBUG => 1;

sub new {
    my $self = bless {} => shift;

    $self->{'conf'} = LoadFile(shift);

    return $self;
}

sub build {
    my ($self, $conf) = @_;
    my ($builddir, $report_path, $perlbrew);

    print "Creating report_path=$report_path\n";
    system("mkdir -p $report_path");

    die "Couldn't create $builddir !" unless -e $builddir;
    my $cwd = getcwd;
    chdir $builddir;

    if ($perlbrew) {
        my $source_perlbrew = "source $ENV{HOME}/perl5/perlbrew/etc/bashrc";
        for my $perl ( glob "$ENV{HOME}/perl5/perlbrew/perls/perl-5.*" ) {
            my $logfile = "$report_path/$perl.txt";
            system("$source_perlbrew && perlbrew switch $perl");
            $self->actually_build($logfile);
        }
    } else {
        my $perl = $^V;
        my $logfile = "$report_path/$perl.txt";
        $self->actually_build($logfile);
    }
    chdir $cwd;
}

sub actually_build () {
    my ($self, $logfile) = @_;
    if ( -e 'dist.ini' ) {
        print "Found dist.ini, using Dist::Zilla\n";
        my $cmd = <<CMD;
dzil authordeps | cpanm
cpanm --installdeps .
HARNESS_VERBOSE=1 dzil test >> $logfile  2>&1
CMD
        system $cmd;
    } elsif ( -e 'Build.PL' ) {
        print "Found Build.PL, using Build.PL\n";
        my $cmd = <<CMD;
perl Build.PL
# ./Build installdeps is not available in older Module::Build's
cpanm --installdeps .
HARNESS_VERBOSE=1 ./Build test --verbose >> $logfile 2>&1
CMD
        system $cmd;
    } elsif ( -e 'Makefile.PL') {
        print "Hoping to find Makefile.PL\n";
        my $cmd = <<CMD;
        perl Makefile.PL
        cpanm --installdeps .
        make
        HARNESS_VERBOSE=1 make test >> $logfile 2>&1
CMD
        system($cmd);
    } else {
        die "Don't know how to build or test this!";
    }
}
