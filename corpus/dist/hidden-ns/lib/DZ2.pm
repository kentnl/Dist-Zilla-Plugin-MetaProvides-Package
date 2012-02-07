use strict;
use warnings;

package DZ2;

# ABSTRACT: this is a sample package for testing Dist::Zilla;

sub main {
    return 1;
}

package    # Hide me from indexing
  A::Hidden::Package;

sub hidden {
    return 2;
}

package A::_Local::Package;

sub private {
    return 3;
}

1;

__END__

=head1 NAME

DZ2

=cut
