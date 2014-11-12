# Interchange6::Cart - Interchange6 cart class

package Interchange6::Cart;

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=cut

use strict;
use Carp;
use DateTime;
use Interchange6::Cart::Cost;
use Interchange6::Cart::Product;
use Scalar::Util 'blessed';
use Try::Tiny;
use Moo;
use MooseX::CoverableModifiers;
use MooX::HandlesVia;
use Interchange6::Types;

with 'Interchange6::Role::Costs';

use namespace::clean;

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=head1 SYNOPSIS

  my $cart = Interchange6::Cart->new();

  $cart->add( sku => 'ABC', name => 'Foo', price => 23.45 );

  $cart->update( sku => 'ABC', quantity => 3 );

  my $product = Interchange::Cart::Product->new( ... );

  $cart->add($product);

  $cart->apply_cost( ... );

  my $total = $cart->total;

=head1 ATTRIBUTES

=head2 id

Cart id can be used for subclasses, e.g. primary key value for carts in the database.

=cut

has id => (
    is  => 'rw',
    isa => Str,
);

=head2 name

The cart name. Default is 'main'.

=cut

has name => (
    is       => 'ro',
    isa      => AllOf [ Defined, NotEmpty, VarChar [255] ],
    default  => 'main',
    writer   => 'rename',
);

=head2 products

Called without args returns a hash reference of L<Interchange6::Cart::Product>. Should not normally be called with args but rather via the various L</PRODUCT METHODS> detailed below.

=cut

has products => (
    is  => 'rwp',
    isa => ArrayRef [ InstanceOf ['Interchange::Cart::Product'] ],
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        clear          => 'clear',
        count          => 'count',
        is_empty       => 'is_empty',
        product_get    => 'get',
        product_index  => 'first_index',
        products_array => 'elements',
        _delete        => 'delete',
        _product_push  => 'push',
        _product_set   => 'set',
    },
    init_arg => undef,
);

=head2 sessions_id

The session ID for the cart.

=cut

has sessions_id => (
    is      => 'ro',
    clearer => 1,
    writer  => 'set_sessions_id',
);

=head2 subtotal

Returns current cart subtotal excluding costs.

=cut

has subtotal => (
    is        => 'lazy',
    clearer   => 1,
    predicate => 1,
);

sub _build_subtotal {
    my $self = shift;

    my $subtotal = 0;

    map { $subtotal += $_->total } $self->products_array;

    return sprintf( "%.2f", $subtotal );
}

=head2 total

Returns current cart total including costs.

=cut

has total => (
    is        => 'lazy',
    clearer   => 1,
    predicate => 1,
);

sub _build_total {
    my $self = shift;

    my $subtotal = $self->subtotal;

    return sprintf( "%.2f", $subtotal + $self->_calculate($subtotal) );
}

=head2 users_id

The user id of the logged in user.

=cut

has users_id => (
    is     => 'ro',
    isa    => Str,
    writer => 'set_users_id',
);

=head1 METHODS

See L<Interchange6::Role::Costs> for details of cost attributes and methods.

=head2 clear

Removes all products from the cart.

=cut

around clear => sub {
    my ( $orig, $self ) = @_;

    # fire off the clear
    $orig->( $self, @_ );
    $self->clear_subtotal;
    $self->clear_total;

    return;
};

=head2 count

Returns the number of different products in the shopping cart. If you have 5 apples and 6 pears it will return 2 (2 different products).

=head2 is_empty

Return boolean 1 or 0 depending on whether the cart is empty or not.

=head2 product_get($index)

Returns the product at the specified index;

=head2 product_index( sub {...})

This method returns the index of the first matching product in the cart. The matching is done with a subroutine reference you pass to this method. The subroutine will be called against each element in the array until one matches or all elements have been checked.

This method requires a single argument.

  my $index = $cart->product_index( sub { $_->sku eq 'ABC' } );

=head2 products_array

Returns an array of Interchange::Cart::Product(s)

=head2 new

Inherited method. Returns a new Cart object.

=head2 add($product)

Add product to the cart. Returns product in case of success.

The product is an L<Interchange6::Cart::Product> or a hash (reference) of product attributes that would be passed to Interchange6::Cart::Product->new().

=cut

sub add {
    my $self    = shift;
    my $product = $_[0];
    my ( $index, $oldproduct, $update );

    if ( blessed($product) ) {
        die "product argument is not an Interchange6::Cart::Product"
          unless ( $product->isa('Interchange6::Cart::Product') );
    }
    else {

        # we got a hash(ref) rather than an Product

        my %args;

        if ( is_HashRef($product) ) {

            # copy args
            %args = %{$product};
        }
        else {

            %args = @_;
        }

        $product = 'Interchange6::Cart::Product'->new(%args);

        unless ( blessed($product)
            && $product->isa('Interchange6::Cart::Product') )
        {
            die "failed to create cart product.";
        }
    }

   # cart may already contain an product with the same sku
   # if so then we add quantity to existing product otherwise we add new product

    $index = $self->product_index( sub { $_->sku eq $product->sku } );

    if ( $index >= 0 ) {

        # product already exists in cart so we need to add new quantity to old

        $oldproduct = $self->product_get($index);

        $product->set_quantity( $oldproduct->quantity + $product->quantity );

        $self->_product_set( $index, $product );

        $update = 1;
    }
    else {

        # a new product for this cart

        $product->cart( $self );
        $self->_product_push($product);
    }

    $self->clear_subtotal;
    $self->clear_total;

    return $product;
}

=head2 find

Searches for an cart product with the given SKU.
Returns cart product in case of sucess or undef on failure.

  if ($product = $cart->find(9780977920174)) {
      print "Quantity: $product->{quantity}.\n";
  }

=cut

sub find {
    my ( $self, $sku ) = @_;

    for my $cartproduct ( $self->products_array ) {
        if ( $sku eq $cartproduct->sku ) {
            return $cartproduct;
        }
    }

    return undef;
}

=head2 has_subtotal

predicate on L</subtotal>.

=head2 has_total

predicate on L</total>.

=head2 quantity

Returns the sum of the quantity of all products in the shopping cart,
which is commonly used as number of products. If you have 5 apples and 6 pears it will return 11.

  print 'Products in your cart: ', $cart->quantity, "\n";

=cut

sub quantity {
    my $self = shift;
    my $qty  = 0;

    map { $qty += $_->quantity } $self->products_array;

    return $qty;
}

=head2 remove($sku)

Remove product from the cart. Takes SKU of product to identify the product.

=cut

sub remove {
    my ( $self, $arg ) = @_;

    my $index = $self->product_index( sub { $_->sku eq $arg } );

    # remove product from our array
    my $ret = $self->_delete($index);
    die "remove sku $arg failed" unless defined $ret;

    $self->clear_subtotal;
    $self->clear_total;
    return $ret;
}

=head2 seed $product_ref

Seeds products within the cart from $product_ref.

B<NOTE:> use with caution since any existing products in the cart will be lost.

  $cart->seed([
      { sku => 'BMX2015', price => 20, quantity = 1 },
      { sku => 'KTM2018', price => 400, quantity = 5 },
      { sku => 'DBF2020', price => 200, quantity = 5 },
  ]);

=cut

sub seed {
    my ( $self, $product_ref ) = @_;
    my ( $args, $product );

  PRODUCT: for $args ( @{ $product_ref || [] } ) {

        $product = Interchange6::Cart::Product->new($args);
        unless ( blessed($product)
            && $product->isa('Interchange6::Cart::Product') )
        {
            $self->clear_subtotal;
            $self->clear_total;
            die "failed to create product.";
        }

        $self->_product_push($product);
    }
    $self->clear_subtotal;
    $self->clear_total;

    return $self->products;
}

=head2 set_sessions_id

Writer method for L<sessions_id>.

=head2 update

Update quantity of products in the cart.

Parameters are pairs of SKUs and quantities, e.g.

  $cart->update(9780977920174 => 5,
                9780596004927 => 3);

A quantity of zero is equivalent to removing this product.

Returns updated products that are still in the cart. Products removed
via quantity 0 or products for which quantity has not changed will not
be returned.

=cut

sub update {
    my ( $self, @args ) = @_;
    my ( $sku, $qty, $product, $update, @products );

  ARGS: while ( @args > 0 ) {
        $sku = shift @args;
        $qty = shift @args;

        unless ( $product = $self->find($sku) ) {
            die "Product for $sku not found in cart.";
        }

        if ( $qty == 0 ) {
            $self->remove($sku);
            next;
        }

        # jump to next product if quantity stays the same
        next ARGS if $qty == $product->quantity;

        $product->set_quantity($qty);
        $self->clear_subtotal;
        $self->clear_total;
        push @products, $product;
    }
    return wantarray ? @products : \@products;
}

# after cost changes we need to clear the total

after apply_cost => sub {
    my $self = shift;
    $self->clear_subtotal;
    $self->clear_total;
};
after clear_costs => sub {
    my $self = shift;
    $self->clear_subtotal;
    $self->clear_total;
};

=head1 AUTHORS

 Stefan Hornburg (Racke), <racke@linuxia.de>
 Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
