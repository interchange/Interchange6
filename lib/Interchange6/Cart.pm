# Interchange6::Cart - Interchange6 cart class

package Interchange6::Cart;

use strict;
use Carp;
use DateTime;
use Interchange6::Cart::Product;
use Scalar::Util 'blessed';
use Try::Tiny;
use Moo;
use MooX::HandlesVia;
use Interchange6::Types;
use Interchange6::Hook;

with 'Interchange6::Role::Errors';
with 'Interchange6::Role::Hookable';

use namespace::clean;

use constant CART_DEFAULT => 'main';

# attributes

has costs => (
    is          => 'rwp',
    isa         => ArrayRef [HashRef],
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        clear_cost => 'clear',
        cost_get   => 'get',
        _cost_push => 'push',
        get_costs  => 'elements',
    },
    init_arg => undef,
);

has created => (
    is      => 'ro',
    isa     => DateAndTime,
    default => sub { DateTime->now },
);

# Cart id can be used for subclasses, e.g. primary key value for carts in the
# database.

has id => (
    is  => 'rw',
    isa => Str,
);

has last_modified => (
    is      => 'rwp',
    isa     => DateAndTime,
    default => sub { DateTime->now },
);

has name => (
    is       => 'rw',
    isa      => AllOf [ Defined, NotEmpty, VarChar [255] ],
    default  => CART_DEFAULT,
    required => 1,
    reader   => 'get_name',
    writer   => 'set_name',
);

# in addition to the standard accessors products has a number of public and
# private methods supplied to us by MooX::HandlesVia

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
    reader   => 'get_products',
    writer   => 'set_products',
    init_arg => undef,
);

has sessions_id => (
    is      => 'rwp',
    isa     => Str,
    clearer => 1,
    reader  => 'get_sessions_id',
    writer  => '_set_sessions_id',
);

# subtotal and total are declared lazy with a builder and clearer so that
# instead of tracking whether their values are cached we can just call:
#   $self->clear_subtotal
# and then when the accessor is next called the builder method calculates
# the new value for us

has subtotal => (
    is       => 'ro',
    isa      => Num,
    builder  => '_build_subtotal',
    lazy     => 1,
    clearer  => 1,
    init_arg => undef,
);

has total => (
    is       => 'ro',
    isa      => Num,
    builder  => '_build_total',
    lazy     => 1,
    clearer  => 1,
    init_arg => undef,
);

has users_id => (
    is     => 'rwp',
    isa    => Str,
    reader => 'get_users_id',
    writer => '_set_users_id',
);

# builders

sub _build_subtotal {
    my $self = shift;

    my $subtotal = 0;

    for my $product ( $self->products_array ) {
        $subtotal += $product->price * $product->quantity;
    }

    return $subtotal;
}

sub _build_total {
    my $self = shift;

    my $subtotal = $self->subtotal;

    my $total = $subtotal + $self->_calculate($subtotal);

    return $total;
}

# before/after/around various methods

after clear_cost => sub {
    my $self = shift;
    $self->clear_total;
};

around add_hook => sub {
    my ( $orig, $self ) = ( shift, shift );
    my ($hook) = @_;
    my $name = $hook->name;

    # if that hook belongs to the app, register it now and return
    return $self->$orig(@_) if $self->has_hook($name);

    # for now extra hooks cannot be added so die if we got here
    croak "add_hook failed";
};

around clear => sub {
    my ( $orig, $self ) = ( shift, shift );

    $self->clear_error;

    # run hook before clearing the cart
    $self->execute_hook( 'before_cart_clear', $self );
    return if $self->has_error;

    # fire off the clear
    $orig->( $self, @_ );

    $self->clear_subtotal;
    $self->clear_total;
    $self->_set_last_modified( DateTime->now );

    # run hook after clearing the cart
    $self->execute_hook( 'after_cart_clear', $self );

    return;
};

around set_name => sub {
    my ( $orig, $self ) = ( shift, shift );
    my $ret;

    $self->clear_error;

    my $old_name = $self->get_name;

    # run hook before clearing the cart
    $self->execute_hook( 'before_cart_rename', $self, $old_name, $_[0] );
    return if $self->has_error;

    # fire off the rename
    $orig->( $self, @_ );

    $self->_set_last_modified( DateTime->now );

    # run hook after clearing the cart
    $self->execute_hook( 'after_cart_rename', $self, $old_name, $_[0] );

    return $self->get_name;
};

# public methods

sub add {
    my $self    = shift;
    my $product = $_[0];
    my ( $index, $oldproduct, $update );

    $self->clear_error;

    unless ( blessed($product) && $product->isa('Interchange6::Cart::Product') )
    {

        # we got a hash(ref) rather than an Product

        my %args;

        if ( is_HashRef($product) ) {

            # copy args
            %args = %{$product};
        }
        else {

            %args = @_;
        }

        # run hooks before validating product

        $self->execute_hook( 'before_cart_add_validate', $self, \%args );
        return if $self->has_error;

        $product = 'Interchange6::Cart::Product'->new(%args);

        unless ( blessed($product)
            && $product->isa('Interchange6::Cart::Product') )
        {
            $self->set_error("failed to create product.");
            return;
        }
    }

    # $product is now an Interchange6::Cart::Product so run hook

    $self->execute_hook( 'before_cart_add', $self, $product );
    return if $self->has_error;

   # cart may already contain an product with the same sku
   # if so then we add quantity to existing product otherwise we add new product

    $index = $self->product_index( sub { $_->sku eq $product->sku } );

    if ( $index >= 0 ) {

        # product already exists in cart so we need to add new quantity to old

        $oldproduct = $self->product_get($index);

        $product->quantity( $oldproduct->quantity + $product->quantity );

        $self->_product_set( $index, $product );

        $update = 1;
    }
    else {

        # a new product for this cart

        $self->_product_push($product);
    }

    # final hook
    $self->execute_hook( 'after_cart_add', $self, $product, $update );

    $self->clear_subtotal;
    $self->clear_total;
    $self->_set_last_modified( DateTime->now );

    return $product;
}

sub apply_cost {
    my ( $self, %args ) = @_;

    $self->_cost_push( \%args );

    # clear cache for total if this is not an inclusive cost
    $self->clear_total unless $args{inclusive};
}

sub cost {
    my ( $self, $loc ) = @_;
    my ( $cost, $ret );

    if ( defined $loc ) {
        if ( $loc =~ /^\d+$/ ) {

            # cost by position
            $cost = $self->cost_get($loc);
        }
        elsif ( $loc =~ /\S/ ) {

            # cost by name
            for my $c ( $self->get_costs ) {
                if ( $c->{name} eq $loc ) {
                    $cost = $c;
                }
            }
        }
    }

    if ( defined $cost ) {
        $ret = $self->_calculate( $self->subtotal, $cost, 1 );
    }

    return $ret;
}

sub find {
    my ( $self, $sku ) = @_;

    for my $cartproduct ( $self->products_array ) {
        if ( $sku eq $cartproduct->sku ) {
            return $cartproduct;
        }
    }

    return;
}

sub quantity {
    my $self = shift;
    my $qty  = 0;

    for my $product ( $self->products_array ) {
        $qty += $product->quantity;
    }

    return $qty;
}

sub remove {
    my ( $self, $arg ) = @_;
    my ( $index, $product );

    $self->clear_error unless caller eq __PACKAGE__;

    # run hook before locating product
    $self->execute_hook( 'before_cart_remove_validate', $self, $arg );
    return if $self->has_error;

    $index = $self->product_index( sub { $_->sku eq $arg } );

    if ( $index >= 0 ) {

        # run hooks before adding product to cart
        $product = $self->product_get($index);

        $self->execute_hook( 'before_cart_remove', $self, $product );
        return if $self->has_error;

        # remove product from our array
        $self->_delete($index);

        # reset totals & modified before calling hook
        $self->clear_subtotal;
        $self->clear_total;
        $self->_set_last_modified( DateTime->now );

        $self->execute_hook( 'after_cart_remove', $self, $product );
        return if $self->has_error;

        return 1;
    }

    # product missing
    $self->set_error("Product not found in cart: $arg.");
    return;
}

# seed needs to add products directly and must not use $cart->add in order
# to avoid hooks
sub seed {
    my ( $self, $product_ref ) = @_;
    my ( $args, $product, @errors );

  PRODUCT: for $args ( @{ $product_ref || [] } ) {

        # stash any existing error
        push( @errors, $self->error ) if $self->has_error;

        $product = Interchange6::Cart::Product->new($args);
        unless ( blessed($product)
            && $product->isa('Interchange6::Cart::Product') )
        {
            $self->set_error("failed to create product.");
            next PRODUCT;
        }

        $self->_product_push($product);
    }
    push( @errors, $self->error ) if $self->has_error;
    $self->set_error( join( ":", @errors ) ) if scalar(@errors) > 1;

    return $self->products;
}

sub sessions_id {
    my ( $self, $sessions_id ) = @_;

    if ( @_ > 1 ) {

        # set sessions_id for the cart
        my %data = ( sessions_id => $sessions_id );

        $self->execute_hook( 'before_cart_set_sessions_id', $self, \%data );
        return if $self->has_error;

        if ( defined $sessions_id ) {
            $self->_set_sessions_id($sessions_id);
        }
        else {
            # magic undef used on logout to prevent cart contents from
            # beging deleted on session->destroy
            $self->clear_sessions_id;
        }

        $self->execute_hook( 'after_cart_set_sessions_id', $self, \%data );
    }

    return $self->get_sessions_id;
}

sub update {
    my ( $self, @args ) = @_;
    my ( $sku, $qty, $product, $update, @errors );

    $self->clear_error;

  ARGS: while ( @args > 0 ) {
        $sku = shift @args;
        $qty = shift @args;

        # stash any existing error
        push( @errors, $self->error ) if $self->has_error;

        unless ( $product = $self->find($sku) ) {
            $self->set_error("Product for $sku not found in cart.");
            next ARGS;
        }

        if ( $qty == 0 ) {

            $self->remove($sku);
            next;
        }

        # jump to next product if quantity stays the same
        next if $qty == $product->quantity;

        # run hook before updating the cart
        $update = { quantity => $qty };

        $self->execute_hook( 'before_cart_update', $self, $product, $update );
        next ARGS if $self->has_error;

        $product->quantity($qty);

        $self->clear_subtotal;
        $self->clear_total;
        $self->_set_last_modified( DateTime->now );

        $self->execute_hook( 'after_cart_update', $self, $product, $update );
    }
    push( @errors, $self->error ) if $self->has_error;
    $self->set_error( join( ":", @errors ) ) if scalar(@errors) > 1;
}

sub users_id {
    my ( $self, $users_id ) = @_;

    if ( @_ > 1 ) {

        # set users_id for the cart
        my %data = ( users_id => $users_id );

        $self->execute_hook( 'before_cart_set_users_id', $self, \%data );
        return if $self->has_error;

        $self->_set_users_id($users_id);

        $self->execute_hook( 'after_cart_set_users_id', $self, \%data );
    }

    return $self->get_users_id;
}

# private methods

sub _calculate {
    my ( $self, $subtotal, $costs, $display ) = @_;
    my ( $cost_ref, $sum );

    if ( ref $costs eq 'HASH' ) {
        $cost_ref = [$costs];
    }
    elsif ( ref $costs eq 'ARRAY' ) {
        $cost_ref = $costs;
    }
    else {
        $cost_ref = $self->costs;
    }

    $sum = 0;

    for my $calc (@$cost_ref) {
        if ( $calc->{inclusive} && !$display ) {
            next;
        }

        if ( $calc->{relative} ) {
            $sum += $subtotal * $calc->{amount};
        }
        else {
            $sum += $calc->{amount};
        }
    }

    return $sum;
}

# compatibility methods

sub products {
    my $self = shift;
    return $self->get_products;
}

sub name {
    my $self = shift;
    if ( @_ > 0 ) {
        $self->set_name( $_[0] );
    }
    return $self->get_name;
}

1;

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=head1 SYNOPSIS

  my $cart = Interchange6::Cart->new();

  $cart->add( sku => 'ABC', name => 'Foo', price => 23.45 );

  $cart->update( sku => 'ABC', quantity => 3 );

  my $product = Interchange::Cart::Product->new( ... );

  $cart->add($product);

  $cart->apply_cost( ... );

  my $total = $cart->total;

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=head1 METHODS

=head2 new

Returns a new Cart object.

=head2 add($product)

Add product to the cart. Returns product in case of success.

The product is an L<Interchange6::Cart::Product> or a hash (reference) of product attributes that would be passed to Interchange6::Cart::Product->new(). See L<Interchange6::Cart::Product> for details.

=head2 add_hook( $hook );

This binds a coderef to an installed hook.

  $hook = Interchange6::Hook->new(
      name => 'before_cart_remove',
      code => sub {
          my ( $cart, $product ) = @_;
          if ( $product->sku eq '123' ) {
              $cart->set_error('Product not removed due to hook.');
          }
      }
  )

  $cart->add_hook( $hook );

See L</HOOKS> for details of the available hooks.

=head2 apply_cost

Apply cost to cart. apply_cost is a generic method typicaly used for taxes, discounts, coupons, gift certificates,...

B<Example:> Absolute cost

    Uses absolute value for amount. Amount 5 is 5 units of currency used (ie. $5).

    $cart->apply_cost(amount => 5, name => 'shipping', label => 'Shipping');

B<Example:> Relative cost

    Uses percentage instead of value for amount. Amount 0.19 in example is 19%.

    relative is a boolean value (0/1).

    $cart->apply_cost(amount => 0.19, name => 'tax', label => 'VAT', relative => 1);

B<Example:> Inclusive cost

    Same as relative cost, but it assumes that tax was included in the subtotal already, and only displays it (19% of subtotal value in example). Inclusive is a boolean value (0/1).

    $cart->apply_cost(amount => 0.19, name => 'tax', label => 'Sales Tax', relative => 1, inclusive => 1);

=cut

=head2 clear

Removes all products from the cart.

=head2 clear_cost

Removes all the costs previously applied (using apply_cost). Used typically if you have free shipping or something similar, you can clear the costs.

=head2 cost

Returns particular cost by position or by name.

B<Example:> Return tax value by name

  $cart->cost('tax');

Returns value of the tax (absolute value in your currency, not percentage)

B<Example:> Return tax value by position

  $cart->cost(0);

Returns the cost that was first applied to subtotal. By increasing the number you can retrieve other costs applied.

=head2 costs

Returns an array of all costs associated with the cart. Costs are ordered according to the order they were applied.

=head2 count

Returns the number of different products in the shopping cart. If you have 5 apples and 6 pears it will return 2 (2 different products).

=head2 created

Returns the time the cart was created as a DateTime object.

=head2 error

Returns the last error.

=head2 find

Searches for an cart product with the given SKU.
Returns cart product in case of sucess.

  if ($product = $cart->find(9780977920174)) {
      print "Quantity: $product->{quantity}.\n";
  }

=head2 get_name

Returns cart name

=head2 get_products

Returns an arrayref of Interchange::Cart::Product(s)

=head2 get_sessions_id

=head2 get_users_id

=head2 is_empty

Return boolean 1 or 0 depending on whether the cart is empty or not.

=head2 product_get $index

Returns the product at the specified index;

=head2 product_index( sub {...})

This method returns the index of the first matching product in the cart. The matching is done with a subroutine reference you pass to this method. The subroutine will be called against each element in the array until one matches or all elements have been checked.

This method requires a single argument.

  my $index = $cart->product_index( sub { $_->sku eq 'ABC' } );

=head2 products

An alias for get_products for backwards compatibility.

=head2 products_array

Returns an array of Interchange::Cart::Product(s)

=head2 last_modified

Returns the time the cart was last modified as a DateTime object.

=head2 name

An alias for get_name and set_name for backwards compatibility.

  $cart->name

Returns current name of cart (default is 'main').

  $cart->name('newname')

Set new name of cart.

=head2 quantity

Returns the sum of the quantity of all products in the shopping cart,
which is commonly used as number of products. If you have 5 apples and 6 pears it will return 11.

  print 'Products in your cart: ', $cart->quantity, "\n";

=head2 remove($sku)

Remove product from the cart. Takes SKU of product to identify the product.

=head2 seed $product_ref

Seeds products within the cart from $product_ref.

B<NOTE:> use with caution since any existing products in the cart will be lost. This method primarily exists for testing purposes only.

  $cart->seed([
      { sku => 'BMX2015', price => 20, quantity = 1 },
      { sku => 'KTM2018', price => 400, quantity = 5 },
      { sku => 'DBF2020', price => 200, quantity = 5 },
  ]);

=head2 sessions_id

=head2 subtotal

Returns current cart subtotal excluding costs.

=head2 total

Returns current cart total including costs.

=head2 update

Update quantity of products in the cart.

Parameters are pairs of SKUs and quantities, e.g.

  $cart->update(9780977920174 => 5,
                9780596004927 => 3);

Triggers before_cart_update and after_cart_update hooks.

A quantity of zero is equivalent to removing this product,
so in this case the remove hooks will be invoked instead
of the update hooks.

=head2 users_id

Returns the id of the user if user is logged in.

=head1 HOOKS

The following hooks are available:

=over 4

=item before_cart_add_validate

Called in L</add> for items added as hash(ref)s. Not called for products passed into L</add> that are already L<Interchange6::Cart::Product> objects.

Receives: $cart, \%args

=item before_cart_add

Called in L</add> immediately before the Interchange6::Cart::Product is added to the cart.

Receives: $cart, $product

=item after_cart_add

Called in L</add> after product has been added to the cart.

Receives: $cart, $product

=item before_cart_remove_validate

Called at start of L</remove> before arg has been validated.

Receives: $cart, $sku

=item before_cart_remove

Called in L</remove> before product is removed from cart.

Receives: $cart, $product

=item after_cart_remove

Called in L</remove> after product has been removed from cart.

Receives: $cart, $product

=item before_cart_update

=item after_cart_update

=item before_cart_clear

=item after_cart_clear

=item before_cart_set_users_id

=item after_cart_set_users_id

=item before_cart_set_sessions_id

=item after_cart_set_sessions_id

=item before_cart_rename

=item after_cart_rename

=back

=head1 AUTHORS

Stefan Hornburg (Racke), <racke@linuxia.de>
Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
