# Interchange6::Cart - Interchange6 cart class

package Interchange6::Cart;

use strict;
use Data::Dumper;
use DateTime;
use Interchange6::Cart::Item;
use Scalar::Util 'blessed';
use Moo;
use MooX::HandlesVia;
use MooX::Types::MooseLike::Base qw(:all);
use Interchange6::Types qw(HasChars VarChar);

use namespace::clean;

use constant CART_DEFAULT => 'main';

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=head2 CART ATTRIBUTES AND METHODS

=over 11

=item cache_subtotal

=cut

has cache_subtotal => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

=item cache_total

=cut

has cache_total => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

=item costs

Costs such as tax and shipping

=cut

has costs => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

=item created

Time cart was created (DateTime object).

Read-only attribute.
=cut

has created => (
    is      => 'ro',
    isa     => InstanceOf ['DateTime'],
    default => sub { DateTime->now },
);

=item error

Last error

=cut

has error => (
    is      => 'rwp',
    isa     => Str,
    default => '',
);

=item items

Arrayref of Interchange::Cart::Item(s)

=cut

has items => (
    is  => 'rw',
    isa => ArrayRef [ InstanceOf ['Interchange::Cart::Item'] ],
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        clear    => 'clear',
        count    => 'count',
        is_empty => 'is_empty',
    },
);

after clear => sub {
    my $self = shift;
    $self->_set_last_modified( DateTime->now );
};

=item last_modified

Time cart was last modified (DateTime object)

=cut

has last_modified => (
    is      => 'rwp',
    isa     => InstanceOf ['DateTime'],
    default => sub { DateTime->now },
);

=item modifiers

=cut

has modifiers => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

=item name

Name of cart

=cut

has name => (
    is      => 'rw',
    isa     => AllOf [ Defined, HasChars, VarChar [255] ],
    default => CART_DEFAULT,
);

=item subtotal

Current cart subtotal excluding costs

=cut

has subtotal => (
    is      => 'rwp',
    isa     => Num,
    default => 0,
);

=item total

Current cart total including costs

=cut

has total => (
    is      => 'rwp',
    isa     => Num,
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
    my $ret;

    # reset error

    $self->_set_error('');

    unless ( blessed($item) && $item->isa('Interchange6::Cart::Item') ) {

        # we got a hash(ref) rather than an Item

        # TODO: can we use coercion in the attribute instead of this?

        my %args;

        if ( is_HashRef($item) ) {

            # copy args
            %args = %{$item};
        }
        else {

            %args = @_;
        }

        $item = 'Interchange6::Cart::Item'->new(%args);

        unless ( blessed($item) && $item->isa('Interchange6::Cart::Item') ) {
            $self->_set_error("failed to create item: $_");
            return;
        }
    }

    # $item is now an Interchange6::Cart::Item

    # cart may already contain an item with the same sku
    # if so then we add quantity to existing item otherwise we add new item

    unless ( $ret = $self->_combine($item) ) {
        push @{ $self->items }, $item;
        $self->_set_last_modified( DateTime->now );
    }

    return $item;
}

=head2 remove $sku

Remove item from the cart. Takes SKU of item to identify the item.

=cut

sub remove {
    my ( $self, $arg ) = @_;
    my ( $pos, $found, $item );

    $pos = 0;

    # run hooks before locating item
    $self->_run_hook( 'before_cart_remove_validate', $self, $arg );

    for $item ( @{ $self->items } ) {
        if ( $item->sku eq $arg ) {
            $found = 1;
            last;
        }
        $pos++;
    }

    if ($found) {

        # run hooks before adding item to cart
        $item = $self->items->[$pos];

        $self->_run_hook( 'before_cart_remove', $self, $item );

        if ( exists $item->{error} ) {

            # one of the hooks denied removing the item
            $self->_set_error( $item->{error} );
            return;
        }

        # clear cache flags
        $self->cache_subtotal(0);
        $self->cache_total(0);

        # removing item from our array
        splice( @{ $self->items }, $pos, 1 );

        $self->_set_last_modified( DateTime->now );

        $self->_run_hook( 'after_cart_remove', $self, $item );
        return 1;
    }

    # item missing
    $self->_set_error = "Missing item $arg.";

    return;
}

=head2 update

Update quantity of items in the cart.

Parameters are pairs of SKUs and quantities, e.g.

    $cart->update(9780977920174 => 5,
                  9780596004927 => 3);

Triggers before_cart_update and after_cart_update hooks.

A quantity of zero is equivalent to removing this item,
so in this case the remove hooks will be invoked instead
of the update hooks.


=cut

sub update {

    my ( $self, @args ) = @_;
    my ( $ref, $sku, $qty, $item, $new_item );

    while ( @args > 0 ) {
        $sku = shift @args;
        $qty = shift @args;

        unless ( $item = $self->find($sku) ) {
            die "Item for $sku not found in cart.\n";
        }

        if ( $qty == 0 ) {

            # remove item instead
            $self->remove($sku);
            next;
        }

        # jump to next item if quantity stays the same
        next if $qty == $item->{quantity};

        # run hook before updating the cart
        $new_item = { quantity => $qty };

        $self->_run_hook( 'before_cart_update', $self, $item, $new_item );

        if ( exists $new_item->{error} ) {

            # one of the hooks denied the item
            $self->_set_error( $new_item->{error} );
            return;
        }

        $self->_set_last_modified( DateTime->now );

        $self->_run_hook( 'after_cart_update', $self, $item, $new_item );

        $item->quantity($qty);
    }
}

=head2 clear

Removes all items from the cart.

=head2 find

Searches for an cart item with the given SKU.
Returns cart item in case of sucess.

    if ($item = $cart->find(9780977920174)) {
        print "Quantity: $item->{quantity}.\n";
    }

=cut

sub find {
    my ( $self, $sku ) = @_;

    for my $cartitem ( @{ $self->items } ) {
        if ( $sku eq $cartitem->sku ) {
            return $cartitem;
        }
    }

    return;
}

=head2 quantity

Returns the sum of the quantity of all items in the shopping cart,
which is commonly used as number of items. If you have 5 apples and 6 pears it will return 11.

    print 'Items in your cart: ', $cart->quantity, "\n";

=cut

sub quantity {
    my $self = shift;
    my $qty  = 0;

    for my $item ( @{ $self->{items} } ) {
        $qty += $item->quantity;
    }

    return $qty;
}

sub _combine {
    my ( $self, $item ) = @_;

  ITEMS: for my $cartitem ( @{ $self->{items} } ) {
        if ( $item->sku eq $cartitem->sku ) {
            for my $mod ( @{ $self->modifiers } ) {

                # FIXME: modifiers needs to be handled
                #next ITEMS unless($item->{$mod} eq $cartitem->{$mod});
            }

            $cartitem->quantity( $cartitem->quantity + $item->quantity );
            $item->quantity( $cartitem->quantity );

            return 1;
        }
    }

    return 0;
}

sub _run_hook {
    my ( $self, $name, @args ) = @_;
    my $ret;

    if ( $self->{run_hooks} ) {
        $ret = $self->{run_hooks}->( $name, @args );
    }

    return $ret;
}

=head1 AUTHORS

Stefan Hornburg (Racke), <racke@linuxia.de>
Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
