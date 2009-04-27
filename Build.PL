use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Parse::Deb::Control',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Parse/Deb/Control.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Parse-Deb-Control-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
