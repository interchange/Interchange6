# Interchange6::Cart - Interchange6 cart class

package Interchange6::Cart;

use strict;
use Carp;
use Data::Dumper;
use DateTime;
use Interchange6::Cart::Item;
use Scalar::Util 'blessed';
use Try::Tiny;
use Moo;
use MooX::HandlesVia;
use Interchange6::Types;
use Interchange6::Hook;

with 'Interchange6::Role::Hookable';

use namespace::clean;

use constant CART_DEFAULT => 'main';

# attributes

has costs => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has created => (
    is      => 'ro',
    isa     => DateAndTime,
    default => sub { DateTime->now },
);

has error => (
    is        => 'rwp',
    isa       => Str,
    clearer   => 1,
    predicate => 1,
);

has items => (
    is  => 'rw',
    isa => ArrayRef [ InstanceOf ['Interchange::Cart::Item'] ],
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        clear       => 'clear',
        count       => 'count',
        is_empty    => 'is_empty',
        item_get    => 'get',
        item_index  => 'first_index',
        items_array => 'elements',
        _delete     => 'delete',
        _item_push  => 'push',
        _item_set   => 'set',
    },
);

has last_modified => (
    is      => 'rwp',
    isa     => DateAndTime,
    default => sub { DateTime->now },
);

has modifiers => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

has name => (
    is       => 'rw',
    isa      => AllOf [ Defined, NotEmpty, VarChar [255] ],
    default  => CART_DEFAULT,
    required => 1,
);

has subtotal => (
    is      => 'ro',
    isa     => Num,
    builder => '_build_subtotal',
    lazy    => 1,
    clearer => 1,
);

has total => (
    is      => 'ro',
    isa     => Num,
    builder => '_build_total',
    lazy    => 1,
    clearer => 1,
);

# builders

sub _build_subtotal {
    my $self = shift;

    my $subtotal = 0;

    for my $item ( $self->items_array ) {
        $subtotal += $item->price * $item->quantity;
    }

    return $subtotal;
}

sub _build_total {
    my $self = shift;

    my $subtotal = $self->subtotal;

    my $total = $subtotal;

    #my $total = $subtotal + $self->_calculate($subtotal);

    return $total;
}

# before/after/around various methods

around clear => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $ret;

    $self->clear_error;

    # run hook before clearing the cart
    $self->execute_hook( 'before_cart_clear', $self );
    return if $self->has_error;

    # fire off the clear
    $ret = $orig->( $self, @_ );

    $self->clear_subtotal;
    $self->clear_total;
    $self->_set_last_modified( DateTime->now );

    # run hook after clearing the cart
    $self->execute_hook( 'after_cart_clear', $self );
    return if $self->has_error;

    return $ret;
};

around add_hook => sub {
    my ( $orig, $self ) = ( shift, shift );

    # saving caller information
    my ( $package, $file, $line ) = caller(4);    # deep to 4 : user's app code
    my $add_hook_caller = [ $package, $file, $line ];

    my ($hook) = @_;
    my $name = $hook->name;

    # if that hook belongs to the app, register it now and return
    return $self->$orig(@_) if $self->has_hook($name);

    # for now extra hooks cannot be added so die if we got here
    croak "add_hook failed";
};

sub add {
    my $self = shift;
    my $item = $_[0];
    my ( $index, $olditem );

    $self->clear_error;

    unless ( blessed($item) && $item->isa('Interchange6::Cart::Item') ) {

        # we got a hash(ref) rather than an Item

        my %args;

        if ( is_HashRef($item) ) {

            # copy args
            %args = %{$item};
        }
        else {

            %args = @_;
        }

        # run hooks before validating item
        # FIXME: This can only be run if we are passed a hash(ref) since
        # passing an I::C::Item means that the item has already been
        # validated. Maybe this hook should be removed? Maybe a new hook
        # inside Cart::Item would be better?

        $self->execute_hook( 'before_cart_add_validate', $self, \%args );
        return if $self->has_error;

        $item = 'Interchange6::Cart::Item'->new(%args);

        unless ( blessed($item) && $item->isa('Interchange6::Cart::Item') ) {
            $self->_set_error("failed to create item.");
            return;
        }
    }

    # $item is now an Interchange6::Cart::Item so run hook

    $self->execute_hook( 'before_cart_add', $self, $item );
    return if $self->has_error;

    # cart may already contain an item with the same sku
    # if so then we add quantity to existing item otherwise we add new item

    $index = $self->item_index( sub { $_->sku eq $item->sku } );

    if ( $index >= 0 ) {

        # item already exists in cart so we need to add new quantity to old

        $olditem = $self->item_get($index);

        $item->quantity( $olditem->quantity + $item->quantity );

        $self->_item_set( $index, $item );
    }
    else {

        # a new item for this cart

        $self->_item_push($item);
    }

    # final hook
    $self->execute_hook( 'after_cart_add', $self, $item );
    return if $self->has_error;

    $self->clear_subtotal;
    $self->clear_total;
    $self->_set_last_modified( DateTime->now );

    return $item;
}

sub remove {
    my ( $self, $arg ) = @_;
    my ( $index, $item );

    $self->clear_error;

    # run hook before locating item
    $self->execute_hook( 'before_cart_remove_validate', $self, $arg );
    return if $self->has_error;

    $index = $self->item_index( sub { $_->sku eq $arg } );

    if ( $index >= 0 ) {

        # run hooks before adding item to cart
        $item = $self->item_get($index);

        $self->execute_hook( 'before_cart_remove', $self, $item );
        return if $self->has_error;

        # remove item from our array
        $self->_delete($index);

        # reset totals & modified before calling hook
        $self->clear_subtotal;
        $self->clear_total;
        $self->_set_last_modified( DateTime->now );

        $self->execute_hook( 'after_cart_remove', $self, $item );
        return if $self->has_error;

        return 1;
    }

    # item missing
    $self->_set_error("Item not found in cart: $arg.");
    return;
}

sub update {
    my ( $self, @args ) = @_;
    my ( $sku, $qty, $item, $new_item );

    $self->clear_error;

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
        $new_item = $item;
        $new_item->quantity($qty);

        $self->execute_hook( 'before_cart_update', $self, $item, $new_item );
        return if $self->has_error;

        $item->quantity($qty);

        $self->clear_subtotal;
        $self->clear_total;
        $self->_set_last_modified( DateTime->now );

        $self->execute_hook( 'after_cart_update', $self, $item, $new_item );
        return if $self->has_error;
    }
}

sub find {
    my ( $self, $sku ) = @_;

    for my $cartitem ( $self->items_array ) {
        if ( $sku eq $cartitem->sku ) {
            return $cartitem;
        }
    }

    return;
}

sub quantity {
    my $self = shift;
    my $qty  = 0;

    for my $item ( $self->items_array ) {
        $qty += $item->quantity;
    }

    return $qty;
}

1;

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=head1 SYNOPSIS

  my $cart = Interchange6::Cart->new();

  $cart->add( sku => 'ABC', name => 'Foo', price => 23.45 );

  $cart->update( sku => 'ABC', quantity => 3 );

  my $item = Interchange::Cart::Item->new( ... );

  $cart->add($item);

  $cart->apply_cost( ... );

  my $total = $cart->total;

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=head1 METHODS

=head2 new

Returns a new Cart object.

=head2 add($item)

Add item to the cart. Returns item in case of success.

The item is an L<Interchange6::Cart::Item> or a hash (reference) of item attributes that would be passed to Interchange6::Cart::Item->new(). See L<Interchange6::Cart::Item> for details.

=head2 add_hook( $hook );

This binds a coderef to an installed hook.

  $hook = Interchange6::Hook->new(
      name => 'before_cart_remove',
      code => sub {
          my ( $cart, $item ) = @_;
          if ( $item->sku eq '123' ) {
              $cart->_set_error('Item not removed due to hook.');
          }
      }
  )

  $cart->add_hook( $hook );

See </HOOKS> for details of the available hooks.


=head2 clear

Removes all items from the cart.

=head2 cost

Returns particular cost by position or by name.

B<Example:> Return tax value by name

  $cart->cost('tax');

Returns value of the tax (absolute value in your currency, not percentage)

B<Example:> Return tax value by position

  $cart->cost(0);

Returns the cost that was first applied to subtotal. By increasing the number you can retrieve other costs applied.

=back

=head2 costs

Returns an array of all costs associated with the cart. Costs are ordered according to the order they were applied.

=head2 count

Returns the number of different items in the shopping cart. If you have 5 apples and 6 pears it will return 2 (2 different items).

=head2 created

Returns the time the cart was created as a DateTime object.

=head2 error

Returns the last error.

=head2 find

Searches for an cart item with the given SKU.
Returns cart item in case of sucess.

  if ($item = $cart->find(9780977920174)) {
      print "Quantity: $item->{quantity}.\n";
  }

=head2 is_empty

Return boolean 1 or 0 depending on whether the cart is empty or not.

=head2 item_get $index

Returns the item at the specified index;

=head2 item_index( sub {...})

This method returns the index of the first matching item in the cart. The matching is done with a subroutine reference you pass to this method. The subroutine will be called against each element in the array until one matches or all elements have been checked.

This method requires a single argument.

  my $index = $cart->item_index( sub { $_->sku eq 'ABC' } );

=head2 items

Returns an arrayref of Interchange::Cart::Item(s)

=head2 items_array

Returns an array of Interchange::Cart::Item(s)

=head2 last_modified

Returns the time the cart was last modified as a DateTime object.

=head2 name

  $cart->name

Returns current name of cart (default is 'main').

  $cart->name('newname')

Set new name of cart.

=head2 quantity

Returns the sum of the quantity of all items in the shopping cart,
which is commonly used as number of items. If you have 5 apples and 6 pears it will return 11.

  print 'Items in your cart: ', $cart->quantity, "\n";

=head2 remove($sku)

Remove item from the cart. Takes SKU of item to identify the item.

=head2 subtotal

Returns current cart subtotal excluding costs.

=head2 total

Returns current cart total including costs.

=head2 update

Update quantity of items in the cart.

Parameters are pairs of SKUs and quantities, e.g.

  $cart->update(9780977920174 => 5,
                9780596004927 => 3);

Triggers before_cart_update and after_cart_update hooks.

A quantity of zero is equivalent to removing this item,
so in this case the remove hooks will be invoked instead
of the update hooks.

=head1 AUTHORS

Stefan Hornburg (Racke), <racke@linuxia.de>
Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
