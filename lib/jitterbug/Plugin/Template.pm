package jitterbug::Plugin::Template;

use Dancer ':syntax';
use Dancer::Plugin;

add_hook(
    'before_template',
    sub {
        my $tokens = shift;
        $tokens->{uri_base} = request->base;
    }
);

register_plugin;

1;
