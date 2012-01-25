package jitterbug::Test;
use strict;
use warnings;
use FindBin qw($Bin);

use Dancer::Config qw/setting/;
use jitterbug::Schema;
use YAML qw/LoadFile/;
use File::Spec;
use File::Temp qw/tempdir/;

sub init {
    #my $db_dir = tempdir( CLEANUP => 1 );
    # TODO: this should be pulled from the config file
    my $db_file = File::Spec->catfile( qw/t data jitterbug.db/ );
    my $dsn     = 'dbi:SQLite:dbname=' . $db_file;
    my $schema  = jitterbug::Schema->connect($dsn);
    _setting($dsn);
    $schema->deploy unless -s $db_file;
}

sub _setting {
    my $dsn = shift;
    setting plugins => {
        DBIC => {
            schema => {
                skip_automake => 1,
                pckg          => "jitterbug::Schema",
                connect_info  => [$dsn]
            }
        }
    };
    setting layout   => 'main';
    setting template => "xslate";
    setting views    => 'views';
    setting engines  => {
        xslate => {
            path  => [ '/' ],
            type  => 'text',
            cache => 0,
        }
    };

}

1;


