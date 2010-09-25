package jitterbug;

use Dancer ':syntax';
use jitterbug::Plugin::Redis;
use jitterbug::Plugin::Template;

our $VERSION = '0.1';

load_app 'jitterbug::Hook',       prefix => '/hook';
load_app 'jitterbug::Project',    prefix => '/project';
load_app 'jitterbug::WebService', prefix => '/api';
load_app 'jitterbug::Task',       prefix => '/task';

get '/' => sub {
    my @projects = redis->smembers(key_projects);
    my @builds = redis->smembers(key_tasks);
    template 'index', {projects => \@projects, builds => \@builds};
};

true;
