use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Moose;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.002 qw( dztest );

my $test = dztest();
$test->add_file(
  'dist.ini' => simple_ini(
    'GatherDir',    #
    [
      'MetaProvides::Package' => {
        inherit_version => 0,                   #
        inherit_missing => 1,                   #
        finder          => ':InstallModules',
      }
    ]
  )
);
$test->add_file( 'lib/DZ2.pm', <<'EOF');
use strict;
use warnings;

package DZ2;

# ABSTRACT: this is a sample package for testing Dist::Zilla;

sub main {
  return 1;
}

1;

__END__

=head1 NAME

DZ2

=cut
EOF

$test->build_ok;

my $zilla = $test->builder;

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

done_testing;
