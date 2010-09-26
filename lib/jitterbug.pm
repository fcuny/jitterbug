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

    my @proj_name = redis->smembers(key_projects);
    my @projects  = ();

    foreach (@proj_name) {
        my $proj = redis->get( key_project($_) );
        next unless $proj;
        my $desc = from_json($proj);
        my @ids  = redis->smembers( key_builds_project($_) );
        my $last_build;
        if (!@ids) {
            my $res = redis->get( pop @ids );
            if ($res) {
                $last_build = from_json($res);
            }
        }
        else {
            $last_build = { timestamp => '' };
        }
        $desc->{last_build} = $last_build;
        push @projects, $desc;
    }

    @projects =
      sort { $b->{last_build}->{timestamp} cmp $a->{last_build}->{timestamp} }
      @projects;

    my @tasks = redis->smembers(key_tasks);
    template 'index', {projects => \@projects, tasks => \@tasks};
};

true;
