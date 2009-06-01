package Dist::Zilla::Plugin::MetaProvides::Class;

# $Id:$
use strict;
use warnings;
use Moose;
use Moose::Autobox;
use MooseX::Has::Sugar;
use MooseX::Types::Moose             (':all');
use Dist::Zilla::MetaProvides::Types (':all');
use Class::Discover                  ();

use aliased 'Dist::Zilla::MetaProvides::ProvideRecord' => 'Record', ();

use namespace::autoclean;
with 'Dist::Zilla::Role::MetaProvider::Provider';

sub _classes_for {
  my ( $self, $filename, $content ) = @_;
  my ($scanparams) = {
    keywords => {
      class => 1,
      role  => 1,
    },
    files => [$filename],
    file  => $filename,
  };
  my $to_record = sub {
    Record->new(
      module  => $_->keys->at(0),
      file    => $filename,
      version => $_->values->at(0)->{version},
      parent  => $self,
    );
  };
  return [
    Class::Discover->_search_for_classes_in_file( $scanparams, \$content ) ]
    ->map($to_record)->flatten;
}

sub provides {
  my $self        = shift;
  my $perl_module = sub { $_[0]->name =~ m{\.pm$} };
  my $get_records = sub {
    $self->_classes_for( $_[0]->name, $_[0]->content );
  };

  return $self->zilla->files->grep($perl_module)->map($get_records)->flatten;

}

__PACKAGE__->meta->make_immutable;
1;
