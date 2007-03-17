use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
                         module_name => 'Games::WoW::Armory',
                         license     => 'perl',
                         dist_author => 'franck cuny <franck.cuny@gmail.com>',
                         dist_version_from => 'lib/Games/WoW/Armory.pm',
                         requires          => {
                                       'Test::More'            => 0,
                                       'version'               => 0,
                                       'LWP::UserAgent'        => 0,
                                       'XML::Simple'           => 0,
                                       'Class::Accessor::Fast' => 0,
                         },
                         add_to_cleanup => [ 'Games::WoW::Armory-*' ],
);

$builder->create_build_script();
