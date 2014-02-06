#!/usr/bin/env perl
## no critic (Modules::RequireVersionVar)

# FILENAME: bundle_to_ini.pl
# CREATED: 02/06/14 01:48:56 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Write an INI file from a bundle

use 5.008;    #utf8
use strict;
use warnings;
use utf8;

use Carp qw( croak carp );
use Perl::Critic::ProfileCompiler::Util qw( create_bundle );

## no critic (ErrorHandling::RequireUseOfExceptions)
my $bundle = create_bundle('Example::Author::KENTNL');
$bundle->configure;

my @stopwords = (
  qw(
    versionless
    metadata
    conformant
    autovivification
    ),
);
for my $wordlist (@stopwords) {
  $bundle->add_or_append_policy_field( 'Documentation::PodSpelling' => ( 'stop_words' => $wordlist ) );
}
$bundle->add_or_append_policy_field(
  'Subroutines::ProhibitCallsToUndeclaredSubs' => (
    exempt_subs => join q[ ],
    qw(
      MooseX::Types::subtype
      MooseX::Types::where
      MooseX::Types::as
      MooseX::Types::ModVersion
      MooseX::Types::ProviderObject
      ),
  ),
);
$bundle->remove_policy('Documentation::RequirePodLinksIncludeText');
$bundle->remove_policy('Bangs::ProhibitDebuggingModules');

my $inf = $bundle->actionlist->get_inflated;

my $config = $inf->apply_config;

{
  open my $rcfile, '>', './perlcritic.rc' or croak 'Cant open perlcritic.rc';
  $rcfile->print( $config->as_ini, "\n" );
  close $rcfile or croak 'Something fubared closing perlcritic.rc';
}
my $deps = $inf->own_deps;
{
  open my $depsfile, '>', './perlcritic.deps' or croak 'Cant open perlcritic.deps';
  for my $key ( sort keys %{$deps} ) {
    $depsfile->printf( "%s~%s\n", $key, $deps->{$key} );
    *STDERR->printf( "%s => %s\n", $key, $deps->{$key} );
  }
  close $depsfile or carp 'Something fubared closing perlcritic.deps';
}

