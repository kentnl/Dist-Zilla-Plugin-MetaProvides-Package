use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Moose;
use Dist::Zilla::Util::Test::KENTNL 0.01000011 qw( test_config );

sub conf {
  return test_config(
    {
      dist_root => 'corpus/dist/perl-5-14',
      ini       => [ 'GatherDir', [ 'MetaProvides::Package' => {@_} ] ],
      build     => 1,

    }
  );
}

TODO: {
    local $TODO = "5.14 style package declarations are not yet supported by Module::Extract::[Namespaces,VERSION]";


subtest basic_implementation_tests => sub {
  my $zilla;

  is(
    exception {
      $zilla = conf(
          inherit_version => 0, inherit_missing => 1 
      );
    },
    undef,
    'Dist construction succeeded'
  );

  my $plugin;

  is(
    exception {
      $plugin = $zilla->plugin_named('MetaProvides::Package');
    },
    undef,
    'Found MetaProvides::Package'
  );

  isa_ok( $plugin, 'Dist::Zilla::Plugin::MetaProvides::Package' );
  meta_ok( $plugin, 'Plugin is mooseified' );
  does_ok( $plugin, 'Dist::Zilla::Role::MetaProvider::Provider', 'does the Provider Role' );
  does_ok( $plugin, 'Dist::Zilla::Role::Plugin', 'does the Plugin Role' );
  is( exception {
      has_attribute_ok( $plugin, 'inherit_version' );
  }, undef, 'has_attribute should not fail');
  is( exception {
    has_attribute_ok( $plugin, 'inherit_missing' );
  }, undef, 'has_attribute should not fail');
  is( exception {
  has_attribute_ok( $plugin, 'meta_noindex' );
  }, undef, 'has_attribute should not fail');
  is( exception {
      is( $plugin->meta_noindex, '1', "meta_noindex default is 1" );
  }, undef, 'method calls should not fail' );
  is( exception {
  is_deeply(
    $plugin->metadata,
    { provides => { DZ2 => { file => 'lib/DZ2.pm', 'version' => '5.5.7' } } },
    'provides data is right'
  );
  }, undef, 'method calls should not fail');
  is( exception {
  is_deeply(
    $plugin->metadata,
    { provides => { DZ2 => { file => 'lib/DZ2.pm', 'version' => '5.5.7' } } },
    'provides data is right'
  );
  }, undef, 'method calls should not fail');
  is( exception {
      isa_ok( [ $plugin->provides ]->[0], 'Dist::Zilla::MetaProvides::ProvideRecord' );
   }, undef, 'method calls should not fail');
};

};
done_testing;
