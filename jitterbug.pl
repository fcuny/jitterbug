#!/usr/bin/env perl
use Dancer;
use lib path(dirname(__FILE__), 'lib');
load_app 'jitterbug';
dance;
