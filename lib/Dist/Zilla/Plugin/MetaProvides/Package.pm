use 5.008;    # open scalar
use strict;
use warnings;

package Dist::Zilla::Plugin::MetaProvides::Package;

our $VERSION = '2.002001';

# ABSTRACT: Extract namespaces/version from traditional packages for provides

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with has around );
use MooseX::LazyRequire;
use MooseX::Types::Moose qw( HashRef Str );
use Module::Metadata 1.000005;
use Dist::Zilla::MetaProvides::ProvideRecord 1.14000000;
use Data::Dump 1.16 ();
use Safe::Isa;
use Dist::Zilla::Util::ConfigDumper 0.003000 qw( config_dumper dump_plugin );


















use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider::Provider';
with 'Dist::Zilla::Role::PPI';

has '+meta_noindex' => ( default => sub { 1 } );











sub provides {
  my $self = shift;
  my (@records);
  for my $file ( @{ $self->_found_files() } ) {
    push @records, $self->_packages_for($file);    #->name, $file->encoded_content, $file->encoding );
  }
  return $self->_apply_meta_noindex(@records);
}





has '_package_blacklist' => (
  isa => HashRef [Str],
  traits  => [ 'Hash', ],
  is      => 'rw',
  default => sub {
    return { map { $_ => 1 } qw( main DB ) };
  },
  handles => { _blacklist_contains => 'exists', },
);









sub _packages_for {
  my ( $self, $file ) = @_;

  if ( not $file->$_does("Dist::Zilla::Role::File") ) {
    $self->log_fatal("API Usage Invalid: _packages_for() takes only a file object");
    return;
  }

  my $meta = $self->_module_metadata_for( $file );
  return unless $meta;
  
  $self->log_debug(
    'Version metadata from ' . $file->name . ' : ' . Data::Dump::dumpf(
      $meta,
      sub {
        if ( $_[1]->$_isa('version') ) {
          return { dump => $_[1]->stringify };
        }
        return { hide_keys => ['pod_headings'], };
      },
    ),
  );

  ## no critic (ProhibitArrayAssignARef)
  my @out;

  my $seen_blacklisted = {};
  my $seen = {};

  for my $namespace ( $meta->packages_inside() ) {
    if ( $self->_blacklist_contains($namespace) ) {
      # note: these ones don't count as namespaces
      # at all for "did you forget a namespace" purposes
      $self->log_debug("Skipping bad namespace: $namespace in " . $file->name);
      next;
    }

    if ( not $self->_can_index($namespace) ){
      # These count for "You had a namespace but you hid it"
      $self->log_debug("Skipping private namespace: $namespace in " . $file->name);
      $seen_blacklisted->{ $namespace } = 1;
      $seen->{ $namespace } = 1;
      next;
    }

    my $v = $meta->version($namespace);

    my (%struct) = (
      module => $namespace,
      file   => $file->name,
      ( ref $v ? ( version => $v->stringify ) : ( version => undef ) ),
      parent => $self,
    );

    $self->log_debug(
      'Version metadata for namespace ' . $namespace . ' in ' . $file->name . ' : ' . Data::Dump::dumpf(
        \%struct,
        sub {
          return { hide_keys => ['parent'] };
        },
      ),
    );
    $seen->{ $namespace } = 1;
    push @out, Dist::Zilla::MetaProvides::ProvideRecord->new(%struct);
  }
  for my $namespace ( @{ $self->_all_packages_for( $file )} ) {
    next if $seen->{ $namespace };
    $self->log_debug("Found hidden namespace: $namespace");
    $seen_blacklisted->{ $namespace } = 1;
  }

  if ( not @out ) {
    if ( not keys %{$seen_blacklisted} ) {
      $self->log( 'No namespaces detected in file ' . $file->name );
    } else {
      $self->log_debug('Only hidden namespaces detected in file ' . $file->name );
    }
    return ();
  }
  return @out;
}

sub _module_metadata_for {
  my ( $self, $file ) = @_;
  
  my $filename = $file->name;
  my $content  = $file->encoded_content;

  ## no critic (InputOutput::RequireBriefOpen, Variables::ProhibitPunctuationVars)
  open my $fh, '<', \$content or $self->log_fatal( [ 'Cant open scalar filehandle for read. %s', $!, ] );
  binmode $fh, sprintf ':encoding(%s)', $file->encoding;

  my $meta = Module::Metadata->new_from_handle( $fh, $file->name, collect_pod => 0 );

  return $meta if $meta;
  
  $self->log_fatal( 'Can\'t extract metadata from ' . $file->name );
  return ();
}

sub _can_index {
  my ( $self, $namespace ) = @_;
  ## no critic (RegularExpressions::RequireLineBoundaryMatching)
  return if $namespace =~ qr/\A_/sx;
  return if $namespace =~ qr/::_/sx;
  return 1;
}

sub _all_packages_for {
  my ( $self, $file ) = @_;
  my $document = $self->ppi_document_for_file($file);
  my $packages = $document->find('PPI::Statement::Package');
  return [ map { $_->namespace } @{$packages} ];
}

around dump_config => config_dumper( __PACKAGE__,
  { attrs => [qw( finder )] },
  sub {
    my ( $self, $payload, ) = @_;
    for my $finder_object ( @{ $self->_finder_objects } ) {
      push @{ $payload->{finder_objects} ||= [] }, dump_plugin($finder_object);
    }
    return;
  },
);

















has finder => (
  isa           => 'ArrayRef[Str]',
  is            => ro =>,
  lazy_required => 1,
  predicate     => has_finder =>,
);





has _finder_objects => (
  isa      => 'ArrayRef',
  is       => ro =>,
  lazy     => 1,
  init_arg => undef,
  builder  => _build_finder_objects =>,
);





sub _vivify_installmodules_pm_finder {
  my ($self) = @_;
  my $name = $self->plugin_name;
  $name .= '/AUTOVIV/:InstallModulesPM';
  if ( my $plugin = $self->zilla->plugin_named($name) ) {
    return $plugin;
  }
  require Dist::Zilla::Plugin::FinderCode;
  my $plugin = Dist::Zilla::Plugin::FinderCode->new(
    {
      plugin_name => $name,
      zilla       => $self->zilla,
      style       => 'grep',
      code        => sub {
        my ( $file, $self ) = @_;
        local $_ = $file->name;
        ## no critic (RegularExpressions)
        return 1 if m{\Alib/} and m{\.(pm)$};
        return 1 if $_ eq $self->zilla->main_module;
        return;
      },
    },
  );
  push @{ $self->zilla->plugins }, $plugin;
  return $plugin;
}





sub _build_finder_objects {
  my ($self) = @_;
  if ( $self->has_finder ) {
    my @out;
    for my $finder ( @{ $self->finder } ) {
      my $plugin = $self->zilla->plugin_named($finder);
      if ( not $plugin ) {
        $self->log_fatal("no plugin named $finder found");
      }
      if ( not $plugin->does('Dist::Zilla::Role::FileFinder') ) {
        $self->log_fatal("plugin $finder is not a FileFinder");
      }
      push @out, $plugin;
    }
    return \@out;
  }
  return [ $self->_vivify_installmodules_pm_finder ];
}





sub _found_files {
  my ($self) = @_;
  my %by_name;
  for my $plugin ( @{ $self->_finder_objects } ) {
    for my $file ( @{ $plugin->find_files } ) {
      $by_name{ $file->name } = $file;
    }
  }
  return [ values %by_name ];
}

around mvp_multivalue_args => sub {
  my ( $orig, $self, @rest ) = @_;
  return ( 'finder', $self->$orig(@rest) );
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaProvides::Package - Extract namespaces/version from traditional packages for provides

=head1 VERSION

version 2.002001

=head1 SYNOPSIS

In your C<dist.ini>:

    [MetaProvides::Package]
    inherit_version = 0    ; optional
    inherit_missing = 0    ; optional
    meta_noindex    = 1    ; optional

=head1 DESCRIPTION

This is a L<< C<Dist::Zilla>|Dist::Zilla >> Plugin that populates the C<provides>
property of C<META.json> and C<META.yml> by absorbing it from your shipped modules,
in a manner similar to how C<PAUSE> itself does it.

This allows you to easily create an authoritative index of what module provides what
version in advance of C<PAUSE> indexing it, which C<PAUSE> in turn will take verbatim.

=head1 QUICK REFERENCE

  ->new(options={})
    finder => ?attr


  A>finder                            # ArrayRef[Str]

  ->dumpconfig                        # HashRef
  ->has_finder                        # via finder
  ->mvp_multivalue_args               # List
  ->provides

  A>_finder_objects                   # ArrayRef[FileFinder]
  A>_package_blacklist                # HashRef[Str]

  ->_blacklist_contains               # via _package_blacklist ( exists )
  ->_build_finder_objects             # for _finder_objects
  ->_found_files                      # ArrayRef[ File ]
  ->_packages_for($file)              # List[Record]
    0   =>   $file                    # Dist::Zilla::Role::File
  ->_vivify_installmodules_pm_finder  # Plugin


  -~- Dist::Zilla::Role::MetaProvider::Provider
  ->new(options={})
    inherit_version => ?attr
    inherit_missing => ?attr
    meta_noindex    => ?attr

  [>] provides

  A>inherit_missing                 # Bool = 1
  A>inherit_version                 # Bool = 1
  A>meta_noindex                    # Bool = 1

  ->dumpconfig                      # HashRef
  ->metadata                        # { provides => ... }

  ->_apply_meta_noindex(options=[]) # Modified @items
    0..$# =>  @items
  ->_resolve_version(options=[])    # ( 'version' , $resolved )
    0     =>  $version              # ()
                                    # ()
  ->_try_regen_meta                 # HashRef


  -~- Dist::Zilla::Role::MetaProvider
  [>] metadata

  -~- Dist::Zilla::Role::Plugin
  ->new(options={})
    plugin_name => ^attr
    zilla       => ^attr
    logger      => ?attr

  A>logger                          #
  A>plugin_name                     # Str
  A>zilla                           # DZil
  ->log                             # via logger
  ->log_debug                       # via logger
  ->log_fatal                       # via logger
  ->mvp_multivalue_args             # ArrayRef
  ->mvp_aliases                     # HashRef
  ->plugin_from_config(options=[])  # Instance
    0 =>  $name
    1 =>  $arg
    2 =>  $section
  ->register_component(options=[])
    0 =>  $name
    1 =>  $arg
    2 =>  $section

=head1 CONSUMED ROLES

=head2 L<Dist::Zilla::Role::MetaProvider::Provider>

=head1 ROLE SATISFYING METHODS

=head2 C<provides>

A conformant function to the L<Dist::Zilla::Role::MetaProvider::Provider> Role.

=head3 signature: $plugin->provides()

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

=head1 ATTRIBUTES

=head2 C<finder>

This attribute, if specified will

=over 4

=item * Override the C<FileFinder> used to find files containing packages

=item * Inhibit autovivification of the C<.pm> file finder

=back

This parameter may be specified multiple times to aggregate a list of finders

=head1 PRIVATE ATTRIBUTES

=head2 C<_package_blacklist>

=head2 C<_finder_objects>

=head1 PRIVATE METHODS

=head2 C<_packages_for>

=head3 signature: $plugin->_packages_for( $file )

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

=head2 C<_vivify_installmodules_pm_finder>

=head2 C<_build_finder_objects>

=head2 C<_found_files>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Dist::Zilla::Plugin::MetaProvides::Package",
    "interface":"class",
    "inherits":"Moose::Object",
    "does":"Dist::Zilla::Role::MetaProvider::Provider"
}


=end MetaPOD::JSON

=head1 OPTIONS INHERITED FROM L<Dist::Zilla::Role::MetaProvider::Provider>

=head2 L<< C<inherit_version>|Dist::Zilla::Role::MetaProvider::Provider/inherit_version >>

How do you want existing versions ( Versions hard-coded into files before running this plug-in )to be processed?

=over 4

=item * DEFAULT: inherit_version = 1

Ignore anything you find in a file, and just probe C<< DZIL->version() >> for a value. This is a sane default and most will want this.

=item * inherit_version = 0

Use this option if you actually want to use hard-coded values in your files and use the versions parsed out of them.

=back

=head2 L<< C<inherit_missing>|Dist::Zilla::Role::MetaProvider::Provider/inherit_missing >>

In the event you are using the aforementioned C<< L</inherit_version> = 0 >>, this determines how to behave when encountering a
module with no version defined.

=over 4

=item * DEFAULT: inherit_missing = 1

When a module has no version, probe C<< DZIL->version() >> for an answer. This is what you want if you want to have some
files with fixed versions, and others to just automatically be maintained by Dist::Zilla.

=item * inherit_missing = 0

When a module has no version, emit a versionless record in the final metadata.

=back

=head2 L<< C<meta_noindex>|Dist::Zilla::Role::MetaProvider::Provider/meta_noindex >>

This is a utility for people who are also using L<< C<MetaNoIndex>|Dist::Zilla::Plugin::MetaNoIndex >>,
so that its settings can be used to eliminate items from the 'provides' list.

=over 4

=item * meta_noindex = 0

By default, do nothing unusual.

=item * DEFAULT: meta_noindex = 1

When a module meets the criteria provided to L<< C<MetaNoIndex>|Dist::Zilla::Plugin::MetaNoIndex >>,
eliminate it from the metadata shipped to L<Dist::Zilla>

=back

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::Plugin::MetaProvides>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
