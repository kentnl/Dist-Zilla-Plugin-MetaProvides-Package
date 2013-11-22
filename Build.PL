
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4202"
  },
  "configure_requires" => {
    "Module::Build" => "0.4202"
  },
  "dist_abstract" => "Extract namespaces/version from traditional packages for provides",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-MetaProvides-Package",
  "dist_version" => "1.15000001",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::MetaProvides::Package",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dump" => "1.16",
    "Dist::Zilla::MetaProvides::ProvideRecord" => "1.14000000",
    "Dist::Zilla::Plugin::FinderCode" => 0,
    "Dist::Zilla::Plugin::MetaProvides" => "1.15000000",
    "Dist::Zilla::Role::MetaProvider::Provider" => 0,
    "IO::String" => 0,
    "Module::Metadata" => "1.000005",
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "MooseX::LazyRequire" => 0,
    "MooseX::Types::Moose" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Dist::Zilla::Util::Test::KENTNL" => "0.01000011",
    "Test::Fatal" => 0,
    "Test::Moose" => 0,
    "Test::More" => "1.001002"
  }
);


my %fallback_build_requires = (
  "Dist::Zilla::Util::Test::KENTNL" => "0.01000011",
  "Module::Build" => "0.4202",
  "Test::Fatal" => 0,
  "Test::Moose" => 0,
  "Test::More" => "1.001002"
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
