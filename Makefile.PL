use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'jitterbug',
    AUTHOR       => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM => 'lib/jitterbug.pm',
    ABSTRACT     => 'YOUR APPLICATION ABSTRACT',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'              => 0,
        'YAML'                    => 0,
        'Dancer'                  => 1.1810,
        'Redis'                   => 0,
        'XML::Feed'               => 0,
        'DateTime'                => 0,
        'JSON'                    => 0,
        'Git:Repository'          => 0,
        'YAML'                    => 0,
        'Dancer::Templae::Xslate' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'jitterbug-*' },
);
