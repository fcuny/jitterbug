package jitterbug::Emailer;

use strict;
use warnings;
use Email::Stuff;
use JSON;

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
    my $self       = shift;
    my $task       = $self->{'task'};
    my $buildconf  = $self->{'conf'}->{'jitterbug'}{'build_process'};
    my $project    = $task->project->name;
    my $tap_output = $self->{'tap_output'};
    my $sha1       = $task->commit->sha256;
    my $desc       = JSON::decode_json( $task->commit->content );
    my $email      = $desc->{'author'}{'email'};

    my $body = <<BODY;
$tap_output
BODY

    my $stuff = Email::Stuff->from($buildconf->{'on_failure_from_email'})
                # bug in Email::Stuff brakes chaining if $email is empty
                ->to($email || " ")
                ->cc($buildconf->{'on_failure_cc_email'})
                ->text_body($body)
                ->subject(
                    $buildconf->{'on_failure_subject_prefix'} . "$project @ $sha1"
                  );
                # Should we attach a build log for convenience?
                # ->attach(io('dead_bunbun_faked.gif')->all,
                #    filename => 'dead_bunbun_proof.gif')
    $self->{'last_email_sent'} = $stuff;

    $stuff->send;

    return $self;
}

1;
