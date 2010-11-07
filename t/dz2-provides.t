use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;
use Dist::Zilla::Util::Test::KENTNL 0.01000011 qw( test_config );

sub conf {
  return test_config(
    {
      dist_root => 'corpus/dist/DZ2',
      ini       => [ 'GatherDir', [ 'MetaProvides::Package' => {@_} ] ],
      build     => 1,
    }
  );
}

subtest basic_implementation_tests => sub {
  my $zilla;

  is(
    exception {

      $zilla = test_config(
        {
          dist_root => 'corpus/dist/DZ2',
          ini       => [ 'GatherDir', [ 'MetaProvides::Package' => { inherit_version => 0, inherit_missing => 1 } ] ],
          build     => 1,
        }
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
  has_attribute_ok( $plugin, 'inherit_version' );
  has_attribute_ok( $plugin, 'inherit_missing' );
  has_attribute_ok( $plugin, 'meta_noindex' );
  is( $plugin->meta_noindex, '1', "meta_noindex default is 1" );
  is_deeply(
    $plugin->metadata,
    { provides => { DZ2 => { file => 'lib/DZ2.pm', 'version' => '0.001' } } },
    'provides data is right'
  );
  isa_ok( [ $plugin->provides ]->[0], 'Dist::Zilla::MetaProvides::ProvideRecord' );
};
done_testing;
