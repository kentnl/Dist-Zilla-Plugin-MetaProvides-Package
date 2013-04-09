use strict;
use warnings;

package Dist::Zilla::Plugin::MetaProvides::Package;
BEGIN {
  $Dist::Zilla::Plugin::MetaProvides::Package::AUTHORITY = 'cpan:KENTNL';
}
{
  $Dist::Zilla::Plugin::MetaProvides::Package::VERSION = '1.14000002';
}

# ABSTRACT: Extract namespaces/version from traditional packages for provides
#
# $Id:$
use Moose;
use MooseX::Types::Moose qw( HashRef Str );
use Moose::Autobox;
use Module::Metadata 1.000005;
use IO::String;
use Dist::Zilla::MetaProvides::ProvideRecord 1.14000000;

require Data::Dump;



use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider::Provider';


has '+meta_noindex' => ( default => sub { 1 } );


sub provides {
    my $self        = shift;
    my $perl_module = sub {
        ## no critic (RegularExpressions)
        $_->name =~ m{^lib[/].*[.](pm|pod)$};
    };
    my $get_records = sub {
        $self->_packages_for( $_->name, $_->content );
    };
    my (@files)   = $self->zilla->files()->flatten;
    my (@records) = @files->grep($perl_module)->map($get_records)->flatten;
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


__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::MetaProvides::Package - Extract namespaces/version from traditional packages for provides

=head1 VERSION

version 1.14000002

=head1 SYNOPSIS

In your C<dist.ini>:

    [MetaProvides::Package]
    inherit_version = 0    ; optional
    inherit_missing = 0    ; optional
    meta_noindex    = 1    ; optional

=head1 ROLES

=head2 L<Dist::Zilla::Role::MetaProvider::Provider>

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

=head1 ROLE SATISFYING METHODS

=head2 provides

A conformant function to the L<Dist::Zilla::Role::MetaProvider::Provider> Role.

=head3 signature: $plugin->provides()

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

=head1 PRIVATE METHODS

=head2 _packages_for

=head3 signature: $plugin->_packages_for( $filename, $file_content )

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

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
