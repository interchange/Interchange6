# Interchange6::Cart::Item - Interchange6 cart item class

package Interchange6::Cart::Item;

use strict;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Interchange6::Types qw(HasChars PositiveNum VarChar);

use namespace::clean;

=head1 NAME 

Interchange6::Cart::Item - Cart item class for Interchange6 Shop Machine

=head1 DESCRIPTION

Cart item class for L<Interchange6>.

=head2 ITEM ATTRIBUTES

Each cart item has the following attributes:

=over 4

=item sku

Unique item identifier.

=cut

has sku => (
    is       => 'ro',
    isa      => AllOf [ Defined, HasChars, VarChar [32] ],
    required => 1,
);

=item name

Item name.

=cut

has name => (
    is       => 'ro',
    isa      => AllOf [ Defined, HasChars, VarChar [255] ],
    required => 1,
);

=item quantity

Item quantity.

=cut

has quantity => (
    is      => 'rw',
    isa     => AllOf [ PositiveNum, Int ],
    default => 1,
);

=item price

Item price.

=cut

has price => (
    is       => 'ro',
    isa      => AllOf [ Defined, PositiveNum ],
    required => 1,
);

=back

=cut

1;
