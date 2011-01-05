use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'jitterbug',
    license             => 'perl',
    dist_author         => 'franck cuny <franck@lumberjaph.net>',
    dist_abstract       => 'Perl smoker that uses Dancer and git',
    dist_version_from   => 'lib/jitterbug.pm',
    include_dirs        => '',
    build_requires => {
        'Test::More'      => 0,
    },
    requires => {
        'YAML'                     => 0,
        'Dancer'                   => 1.1810,
        'XML::Feed'                => 0,
        'DateTime'                 => 0,
        'JSON'                     => 0,
        'Git::Repository'          => 0,
        'YAML'                     => 0,
        'Dancer::Template::Xslate' => 0,
        'Dancer::Plugin::DBIC'     => 0,
        'DBIx::Class'              => 0,
        'SQL::Translator'          => 0,
        'Digest::MD5'              => 0,
        'App::perlbrew'            => 0,
        'Dist::Zilla'              => 0,
    },
    add_to_cleanup      => [ 'jitterbug-' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/franckcuny/jitterbug/tree/master'
        },
    },
);

$builder->create_build_script();
print "Have a great day!\n";
