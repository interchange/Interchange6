# Interchange6::Cart - Interchange6 cart class

package Interchange6::Cart;

use strict;
use DateTime;
use Interchange6::Cart::Item;
use Try::Tiny;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Interchange6::Types qw(DateTime HasChars VarChar);

use namespace::clean;

use constant CART_DEFAULT => 'main';

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=cut

has costs          => ();
has cache_subtotal => ();
has cache_total    => ();
has created        => (
    is      => 'rw',
    isa     => DateTime,
    default => DateTime->now,
);
has error => (
    is  => 'rwp',
    isa => 'Str',
);
has items => (
    is  => 'rw',
    isa => ArrayRef [ InstanceOf ['Interchange::Cart::Item'] ],
);
has last_modified => (
    is      => 'rw',
    isa     => DateTime,
    default => DateTime->now,
);
has modifiers => ();
has name      => (
    is      => 'rw',
    isa     => AllOf [ Defined, HasChars, VarChar [255] ],
    default => CART_DEFAULT,
);
has subtotal => (
    is      => 'rwp',
    isa     => 'Num',
    default => 0,
);
has total => (
    is      => 'rwp',
    isa     => 'Num',
    default => 0,
);

=head2 add $item

Add item to the cart. Add item to the cart. Returns item in case of success.

The item is a hash (reference) which is subject to the following
conditions:

=over 4

=item sku

Item identifier is required.

=item name

Item name is required.

=item quantity

Item quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

Item price is required and a positive number.

Price is required, because you want to maintain the price that was valid at the time of adding to the cart. Should the price in the shop change in the meantime, it will maintain this price. If you would like to update the pages, you have to do it before loading the cart page on your shop.


B<Example:> Add 5 BMX2012 products to the cart

    $cart->add( sku => 'BMX2012', name => 'BMX bike', quantity => 5,
        price => 200);

B<Example:> Add a BMX2012 product to the cart.

    $cart->add( sku => 'BMX2012', name => 'BMX bike', price => 200);

=back

=cut

sub add {
    my $self = shift;
    my ( %args, $ret );

    if ( ref( $_[0] ) ) {

        # copy args
        %args = %{ $_[0] };
    }
    else {
        %args = @_;
    }

    try {
        my $item = Interchange6::Cart::Item->new( \%args );
        return $item;
    }
    catch {
        warn "failed to create item: $_";
        return;
    };
}

1;
