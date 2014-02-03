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

=head2 CART ATTRIBUTES

=over 11

=item cache_subtotal

=cut

has cache_subtotal => ();

=item cache_total

=cut

has cache_total    => ();

=item costs

Costs such as tax and shipping

=cut

has costs          => ();

=item created

Time cart was created (DateTime object)

=cut

has created        => (
    is      => 'rw',
    isa     => DateTime,
    default => DateTime->now,
);

=item error

Last error

=cut

has error => (
    is  => 'rwp',
    isa => 'Str',
);

=item items

Arrayref of cart items

=cut

has items => (
    is  => 'rw',
    isa => ArrayRef [ InstanceOf ['Interchange::Cart::Item'] ],
);

=item last_modified

Time cart was last modified (DateTime object)

=cut

has last_modified => (
    is      => 'rw',
    isa     => DateTime,
    default => DateTime->now,
);

=item modifiers

=cut

has modifiers => ();

=item name

Name of cart

=cut

has name      => (
    is      => 'rw',
    isa     => AllOf [ Defined, HasChars, VarChar [255] ],
    default => CART_DEFAULT,
);

=item subtotal

Current cart subtotal excluding costs

=cut

has subtotal => (
    is      => 'rwp',
    isa     => 'Num',
    default => 0,
);

=item total

Current cart total including costs

=cut

has total => (
    is      => 'rwp',
    isa     => 'Num',
    default => 0,
);

=back

=head2 add $item

Add item to the cart. Returns item in case of success.

The item is an L<Interchange6::Cart::Item> or a hash (reference) which is subject to the following conditions:

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
    my $item = $_[0];

    $self->_set_error(undef);

    if ( ! $item->isa('Interchange6::Cart::Item;) ) {

        # we got a hash(ref) rather than an Item

        my %args;

        if ( is_HashRef($item) ) {

            # copy args
            %args = %{ $item };
        }
        else {

            %args = @_;
        }

        try {
            $item = Interchange6::Cart::Item->new( \%args );
        }
        catch {
            $self->_set_error("failed to create item: $_");
            return;
        };
    }

    # $item is now an Interchange6::Cart::Item

    # cart may already contain an item with the same sku
    # if so then we add quantity to existing item otherwise we add new item

    if ( grep { $_->sku eq $item->sku } @{$cart->items} ) {

        # change quantity of existing item
        $self->update( $item );
    }
    else {

        # new sku
    }
}

=head2 update


=cut

sub update {
}

1;
