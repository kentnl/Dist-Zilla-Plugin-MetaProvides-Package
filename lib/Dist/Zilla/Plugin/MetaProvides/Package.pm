use strict;
use warnings;
package Dist::Zilla::Plugin::MetaProvides::Package;

# ABSTRACT: Extract namespaces/version from traditional packages for provides
#
# $Id:$
use Moose;
use Moose::Autobox;

use Module::Extract::VERSION;
use Module::Extract::Namespaces;
use Dist::Zilla::MetaProvides::ProvideRecord;

=head1 ROLES

=head2 L<Dist::Zilla::Role::MetaProvider::Provider>

=cut

use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider::Provider';

=head1 ROLE SATISFYING METHODS

=head2 provides

A conformant function to the L<Dist::Zila::Role::MetaProvider::Provider> Role.

=head3 signature: $plugin->provides()

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

=cut

sub provides {
  my $self        = shift;
  my $perl_module = sub { $_->name =~ m{^lib\/.*\.(pm|pod)$} };
  my $get_records = sub {
    $self->_packages_for( $_->name, $_->content );
  };

  return $self->zilla->files->grep($perl_module)->map($get_records)->flatten;
}

=head1 PRIVATE METHODS

=head2 _packages_for

=head3 signature: $plugin->_packages_for( $filename, $file_content )

=head3 returns: Array of L<Dist::Zilla::MetaProvides::ProvideRecord>

=cut

sub _packages_for {
  my ( $self, $filename, $content ) = @_;
  my $version   = Module::Extract::VERSION->parse_version_safely($filename);
  my $to_record = sub {
      Dist::Zilla::MetaProvides::ProvideRecord->new(
      module  => $_,
      file    => $filename,
      version => $version,
      parent  => $self,
    );
  };
  return [ Module::Extract::Namespaces->from_file($filename) ]->map($to_record)->flatten;
}

=head1 SEE ALSO

=over 4

=item * L<Dist::Zilla::Plugin::MetaProvides>

=back

=cut

__PACKAGE__->meta->make_immutable;
1;

