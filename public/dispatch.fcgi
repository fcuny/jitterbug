#!/usr/bin/env perl
use Plack::Handler::FCGI;

my $app = do('/home/franck/code/projects/c/jitterbug/jitterbug.pl');
my $server = Plack::Handler::FCGI->new(nproc  => 5, detach => 1);
$server->run($app);
