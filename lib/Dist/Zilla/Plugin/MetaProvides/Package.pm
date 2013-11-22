use strict;
use warnings;

package Dist::Zilla::Plugin::MetaProvides::Package;
BEGIN {
  $Dist::Zilla::Plugin::MetaProvides::Package::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::MetaProvides::Package::VERSION = '1.15000001';
}

# ABSTRACT: Extract namespaces/version from traditional packages for provides

use Moose;
use MooseX::LazyRequire;
use MooseX::Types::Moose qw( HashRef Str );
use Moose::Autobox;
use Module::Metadata 1.000005;
use IO::String;
use Dist::Zilla::MetaProvides::ProvideRecord 1.14000000;
use Data::Dump 1.16 ();




use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider::Provider';


has '+meta_noindex' => ( default => sub { 1 } );


sub provides {
    my $self        = shift;
    my $get_records = sub {
        $self->_packages_for( $_->name, $_->content );
    };
    my (@records);
    for my $file ( @{ $self->_found_files() } ) {
        push @records, $self->_packages_for( $file->name, $file->content );
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
    my ( $self, $filename, $content ) = @_;

    my $fh = IO::String->new($content);

    my $meta = Module::Metadata->new_from_handle( $fh, $filename, collect_pod => 0 );

    if ( not $meta ) {
        $self->log_fatal("Can't extract metadata from $filename");
    }

    $self->log_debug(
        "Version metadata from $filename : " . Data::Dump::dumpf(
            $meta,
            sub {
                if ( ref $_[1] and $_[1]->isa('version') ) {
                    return { dump => $_[1]->stringify };
                }
                return { hide_keys => ['pod_headings'] };
            }
        )
    );
    my $remove_bad = sub {
        my $item = shift;
        return if $item =~ qr/\A_/msx;
        return if $item =~ qr/::_/msx;
        return not $self->_blacklist_contains($item);
    };
    my $to_record = sub {

        my $v = $meta->version($_);
        my (%struct) = (
            module => $_,
            file   => $filename,
            ( ref $v ? ( version => $v->stringify ) : ( version => undef ) ),
            parent => $self,
        );
        $self->log_debug(
            'Version metadata: ' . Data::Dump::dumpf(
                \%struct,
                sub {
                    return { hide_keys => ['parent'] };
                }
            )
        );
        Dist::Zilla::MetaProvides::ProvideRecord->new(%struct);
    };

    my @namespaces = [ $meta->packages_inside() ]->grep($remove_bad)->flatten;

    $self->log_debug( 'Discovered namespaces: ' . Data::Dump::pp( \@namespaces ) . ' in ' . $filename );

    if ( not @namespaces ) {
        $self->log( 'No namespaces detected in file ' . $filename );
        return ();
    }
    return @namespaces->map($to_record)->flatten;

}
around dump_config => sub {
    my ( $orig, $self, @args ) = @_;
    my $config    = $self->$orig(@args);
    my $localconf = {};
    for my $var (qw( finder )) {
        my $pred = 'has_' . $var;
        if ( $self->can($pred) ) {
            next unless $self->$pred();
        }
        if ( $self->can($var) ) {
            $localconf->{$var} = $self->$var();
        }
    }
    $config->{ q{} . __PACKAGE__ } = $localconf;
    return $config;
};


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

around plugin_from_config => sub {
    my ( $orig, $self, @args ) = @_;
    my $plugin = $self->$orig(@args);
    $plugin->_finder_objects;
    return $plugin;
};


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
        }
    );
    $self->zilla->plugins->push($plugin);
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

version 1.15000001

=head1 SYNOPSIS

In your C<dist.ini>:

    [MetaProvides::Package]
    inherit_version = 0    ; optional
    inherit_missing = 0    ; optional
    meta_noindex    = 1    ; optional

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

=head3 signature: $plugin->_packages_for( $filename, $file_content )

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

This software is copyright (c) 2013 by Kent Fredric.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
