use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'testing',
    license             => 'perl',
    dist_author         => 'The Gods Themselves',
    dist_abstract       => 'This universe is only a test',
    dist_version        => 1,
    include_dirs        => '',
    build_requires => {
        'Test::More'      => 0,
    },
    requires => {
        'YAML'                     => 0,
    },
    add_to_cleanup      => [ '' ],
    create_makefile_pl  => 'traditional',
    meta_merge     => {
        resources => {
            repository  => 'http://github.com/solgenomics/testing/tree/master'
        },
    },
);

$builder->create_build_script();
print "Have a great day!\n";
