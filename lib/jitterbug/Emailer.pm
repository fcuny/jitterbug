package jitterbug::Emailer;

use strict;
use warnings;
use Email::Stuff;
use JSON;

sub new {
    my $self = bless {} => shift;
    my ($conf,$task,$tap_output,$status) = @_;
    # smelly
    $self->{'conf'}       = $conf;
    $self->{'task'}       = $task;
    $self->{'tap_output'} = $tap_output;
    $self->{'status'}     = $status;

    return $self;
}

sub _make_body {
    my ($header, $message, $tap, $footer) = @_;

    no warnings 'uninitialized';
    return <<BODY;
$header
Commit Message:
$message

TAP Output:
$tap
$footer
BODY

}
sub run {
    my $self      = shift;
    my $task      = $self->{'task'};
    my $status    = $self->{'status'};
    my $buildconf = $self->{'conf'}->{'jitterbug'}{'build_process'};
    my $project   = $task->project->name;
    my $tap       = $self->{'tap_output'};
    my $sha1      = $task->commit->sha256;
    my $shortsha1 = substr($sha1, 0, 8);
    my $desc      = JSON::decode_json( $task->commit->content );
    my $message   = $desc->{'message'};
    my $header    = $buildconf->{"on_${status}_header"};
    my $footer    = $buildconf->{"on_${status}_footer"};
    my $body      = _make_body($header,$message, $tap, $footer);
    my $summary   = '';

    if ( $tap =~ m/^(Test Summary Report.*)/ms ) {
        $summary = $1;
    }

    # Expand placeholders in our email
    $body =~ s/%%PROJECT%%/$project/g;
    $body =~ s/%%SHA1%%/$sha1/g;
    $body =~ s/%%SUMMARY%%/$summary/g;

    my ($short_message) = split /\n/, $message;

    # Default to the to_email specified in our config. If it isn't set,
    # use the author email 
    my $email = $buildconf->{"on_${status}_to_email"} || $desc->{'author'}{'email'};

    my $stuff = Email::Stuff->from($buildconf->{"on_${status}_from_email"})
                # bug in Email::Stuff brakes chaining if $email is empty
                ->to($email || " ")
                ->cc($buildconf->{"on_${status}_cc_email"})
                ->text_body($body)
                ->subject(
                    $buildconf->{"on_${status}_subject_prefix"} . "$project @ $shortsha1 $short_message"
                  );
                # Should we attach a build log for convenience?
                # ->attach(io('dead_bunbun_faked.gif')->all,
                #    filename => 'dead_bunbun_proof.gif')
    $self->{'last_email_sent'} = $stuff;

    $stuff->send;

    return $self;
}

1;
