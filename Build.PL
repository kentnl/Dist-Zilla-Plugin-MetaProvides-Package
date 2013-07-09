
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4005"
  },
  "configure_requires" => {
    "Module::Build" => "0.4005"
  },
  "dist_abstract" => "Extract namespaces/version from traditional packages for provides",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-MetaProvides-Package",
  "dist_version" => "1.14000003",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::MetaProvides::Package",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dump" => "1.16",
    "Dist::Zilla::MetaProvides::ProvideRecord" => "1.14000000",
    "Dist::Zilla::Plugin::MetaProvides" => "1.14000000",
    "Dist::Zilla::Role::MetaProvider::Provider" => 0,
    "IO::String" => 0,
    "Module::Metadata" => "1.000005",
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "MooseX::Types::Moose" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dist::Zilla::Util::Test::KENTNL" => "0.01000011",
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::Fatal" => 0,
    "Test::Moose" => 0,
    "Test::More" => "0.98"
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
