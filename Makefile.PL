use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'jitterbug',
    AUTHOR       => q{franck cuny <franck@lumberjaph.net>},
    VERSION_FROM => 'lib/jitterbug.pm',
    ABSTRACT     => 'perl/github smoker',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'              => 0,
        'YAML'                    => 0,
        'Dancer'                  => 1.1810,
        'XML::Feed'               => 0,
        'DateTime'                => 0,
        'JSON'                    => 0,
        'Git:Repository'          => 0,
        'YAML'                    => 0,
        'Dancer::Templae::Xslate' => 0,
        'Dancer::Plugin::DBIC'    => 0,
        'DBIx::Class'             => 0,
        'SQL::Translator'         => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'jitterbug-*' },
);
