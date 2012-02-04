
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Dist::Zilla::Util::Test::KENTNL" => "0.01000011",
    "File::Find" => 0,
    "Module::Build" => "0.3601",
    "Test::Fatal" => 0,
    "Test::Moose" => 0,
    "Test::More" => "0.96"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Extract namespaces/version from traditional packages for provides",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "Dist-Zilla-Plugin-MetaProvides-Package",
  "dist_version" => "1.12060502",
  "license" => "perl",
  "module_name" => "Dist::Zilla::Plugin::MetaProvides::Package",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Data::Dump" => 0,
    "Dist::Zilla::MetaProvides::ProvideRecord" => 0,
    "Dist::Zilla::Plugin::MetaProvides" => "1.12044806",
    "Dist::Zilla::Role::MetaProvider::Provider" => 0,
    "File::Temp" => 0,
    "Module::Extract::Namespaces" => "0.14",
    "Module::Extract::VERSION" => "0.13",
    "Moose" => 0,
    "Moose::Autobox" => 0,
    "namespace::autoclean" => 0,
    "perl" => "5.006",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
