use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Moose;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.002000 qw( dztest );

use Module::Metadata 1.000022;

sub nofail(&) {
  my $code = shift;
  return is( exception { $code->() }, undef, "Contained Code should not fail" );
}

my $test = dztest();
$test->add_file(
  'dist.ini' => simple_ini(
    'GatherDir',    #
    [
      'MetaProvides::Package' => {    #
        inherit_version => 0,
        inherit_missing => 1
      }
    ]
  )
);
$test->add_file( 'lib/DZ2.pm', <<'EOF');
use strict;
use warnings;

package DZ2 v5.5.7 {

    # ABSTRACT: this is a sample package for testing Dist::Zilla;

    sub main {
        return 1;
    }

    1;
}

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
nofail { has_attribute_ok( $plugin, 'inherit_version' ) };
nofail { has_attribute_ok( $plugin, 'inherit_missing' ) };
nofail { has_attribute_ok( $plugin, 'meta_noindex' ) };
nofail {
  is( $plugin->meta_noindex, '1', "meta_noindex default is 1" );
};
nofail {
  is_deeply(
    $plugin->metadata,
    { provides => { DZ2 => { file => 'lib/DZ2.pm', 'version' => 'v5.5.7' } } },
    'provides data is right'
  );
};

nofail {
  isa_ok( [ $plugin->provides ]->[0], 'Dist::Zilla::MetaProvides::ProvideRecord' );
};

done_testing;
