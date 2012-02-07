use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Moose;
use Dist::Zilla::Util::Test::KENTNL 0.01000011 qw( test_config );

sub conf {
    return test_config(
        {
            dist_root => 'corpus/dist/hidden-ns',
            ini       => [ 'GatherDir', [ 'MetaProvides::Package' => {@_} ] ],
            build     => 1,
        }
    );
}

subtest basic_implementation_tests => sub {
    my $zilla;

    is(
        exception {
            $zilla = conf( inherit_version => 0, inherit_missing => 1 );
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

    # This crap is needed because 'ok' is mysteriously not working.
    ( not exists $plugin->metadata->{provides}->{'A::_Local::Package'} )
      ? pass('Packages leading with _ are hidden')
      : fail('Packages leading with _ are hidden');

    ( not exists $plugin->metadata->{provides}->{'A::Hidden::Package'} )
      ? pass('Packages with \n are hidden')
      : fail('Packages with \n are hidden');

    isa_ok( [ $plugin->provides ]->[0], 'Dist::Zilla::MetaProvides::ProvideRecord' );
};
done_testing;
