package jitterbug::Emailer;

use strict;
use warnings;
use Email::Stuff;

sub new {
    my $self = bless {} => shift;
    my ($conf,$task,$tap_output) = @_;
    # smelly
    $self->{'conf'} = $conf;
    $self->{'task'} = $task;
    $self->{'tap_output'} = $tap_output;

    return $self;
}

sub run {
    my $self = shift;
    my $buildconf = $conf->{'jitterbug'}{'build_process'};
    my $project   = $task->project->name;

    my $sha1 = $task->commit->sha256;
    my $body = <<BODY;
$tap_output
BODY

    Email::Stuff->from($buildconf->{'on_failure_from_email')
                ->to($buildconf->{'on_failure_to_email'})
                ->cc($buildconf->{'on_failure_cc_email'})
                ->text_body($body)
                ->subject(
                    $buildconf->{'on_failure_subject_prefix'} . "$project @ $sha1"
                  )
                # Should we attach a build log for convenience?
                # ->attach(io('dead_bunbun_faked.gif')->all,
                #    filename => 'dead_bunbun_proof.gif')
                ->send;

    return $self;
}

1;
