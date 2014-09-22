# Interchange6::Cart::Product - Interchange6 cart product class

package Interchange6::Cart::Product;

use strict;
use Moo;
use Interchange6::Types;
with 'Interchange6::Role::Costs';

use namespace::clean;

=head1 NAME 

Interchange6::Cart::Product - Cart product class for Interchange6 Shop Machine

=head1 DESCRIPTION

Cart product class for L<Interchange6>.

See L<Interchange6::Role::Costs> for details of cost attributes and methods.

=head1 ATTRIBUTES

Each cart product has the following attributes:

=head2 id

Can be used by subclasses, e.g. primary key value for cart products in the database.

=cut

has id => (
    is  => 'ro',
    isa => Int,
);

=head2 cart

A reference to the Cart object that this Cart::Product belongs to.

=cut

has cart => (
    is        => 'rw',
    default   => undef,
);

=head2 discount

Discount actual amount in currency for quantity 1 of product. On set this will also update L</discount_percent> to match. Defaults to 0.

=cut

has discount => (
    is        => 'rw',
    isa       => Num,
    default   => 0,
);

sub _calculate_discount {
    my $self = shift;
    return sprintf( "%.2f",
        $self->original_price * $self->discount_percent / 100 )
}

after discount => sub {
    my ( $self, $value ) = @_;
    if ( defined $value ) {
        # FIXME: nasty avoidance of deep recursion
        $self->{discount_percent} = $self->_calculate_discount_percent;
        $self->clear_price;
        $self->clear_subtotal;
        $self->clear_total;
        if ( $self->cart ) {
            $self->cart->clear_subtotal;
            $self->cart->clear_total;
        }
    }
};

=head2 discount_percent

Discount amount in percent for quantity 1 of product. On set this will also update L</discount> to match. Defaults to 0.

=cut

has discount_percent => (
    is        => 'rw',
    isa       => Num,
    default   => 0,
);

sub _calculate_discount_percent {
    my $self = shift;
    return sprintf( "%.2f", $self->discount / $self->original_price * 100 );
}

after discount_percent => sub {
    my ( $self, $value ) = @_;
    if ( defined $value ) {
        # FIXME: nasty avoidance of deep recursion
        $self->{discount} = $self->_calculate_discount;
        $self->clear_price;
        $self->clear_subtotal;
        $self->clear_total;
        if ( $self->cart ) {
            $self->cart->clear_subtotal;
            $self->cart->clear_total;
        }
    }
};

=head2 name

Product name is required.

=cut

has name => (
    is       => 'ro',
    isa      => AllOf [ Defined, NotEmpty, VarChar [255] ],
    required => 1,
);

=head2 original_price

This is the product price B<before> any discount is applied. This attribute is set to the price that the product was created with. It is not possible to change the value of this attribute. The value of L</original_price> is set automatically and should not be set on object creation.

=cut

has original_price => (
    is  => 'rwp',
    isa => PositiveNum,
);

=head2 price

Product price is required and a positive number.

Price is required, because you want to maintain the price that was valid at the time of adding to the cart. Should the price in the shop change in the meantime, it will maintain this price.

=cut

has price => (
    is        => 'rwp',
    isa       => PositiveNum,
    clearer   => 1,
    lazy      => 1,
    builder   => 1,
    required  => 1,
    predicate => 1,
);

sub _build_price {
    my $self = shift;
    my $price = $self->original_price - $self->discount;
    if ( $self->cart ) {
        # already added to cart
        my $cart_discount = $price * $self->cart->discount_percent / 100;
        return sprintf( "%.2f", $price - $cart_discount );
    }
    else {
        # not in cart yet
        return $price;
    }
}

=head2 quantity

Product quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

=cut

has quantity => (
    is      => 'rw',
    isa     => AllOf [ PositiveNum, Int ],
    default => 1,
);

=head2 sku

Unique product identifier is required.

=cut

has sku => (
    is       => 'ro',
    isa      => AllOf [ Defined, NotEmpty, VarChar [32] ],
    required => 1,
);

=head2 subtotal

Subtotal calculated as L</price> * L</quantity>. Lazy set via builder.

=cut

has subtotal => (
    is        => 'lazy',
    isa       => Num,
    clearer   => 1,
    predicate => 1,
);

sub _build_subtotal {
    my $self = shift;
    return sprintf( "%.2f", $self->price * $self->quantity);
}

=head2 total

Total calculated as L</subtotal> plus all L<Interchange6::Role:Costs/costs>.

=cut

has total => (
    is        => 'lazy',
    isa       => Num,
    clearer   => 1,
    predicate => 1,
);

sub _build_total {
    my $self = shift;
    my $subtotal = $self->subtotal;
    return sprintf( "%.2f", $subtotal + $self->_calculate($subtotal) );
}

=head2 uri

Product uri

=cut

has uri => (
    is  => 'rw',
    isa => VarChar [255],
);

=head1 METHODS

=head2 BUILDARGS

Check for illegal setting of both L</discount> and L</discount_percent>.

Check for illegal setting of L</original_price>.

=cut

sub BUILDARGS {
    my $self = shift;
    my %attrs;

    die "Missing required args" unless @_ > 0;

    if ( @_ > 1 ) {
        %attrs = @_;
    }
    else {
        %attrs = %{$_[0]};
    }

    die "Missing required arguments: price" unless exists $attrs{price};

    die "Do not pass original_price to builder - use price instead"
      if defined $attrs{original_price};

    die "Cannot mix discount and discount_percent"
      if ( defined $attrs{discount} && defined $attrs{discount_percent} );

    return \%attrs;
}

=head2 BUILD

Set L</original_price> to supplied value of L</price> and apply discount if either L</discount> or L</discount_percent> is supplied to create new L</price>.

=cut

sub BUILD {
    my $self = shift;

    $self->_set_original_price( $self->price );

    if ( $self->discount ) {
        $self->discount_percent($self->_calculate_discount_percent);
    }
    elsif ( $self->discount_percent ) {
        $self->discount($self->_calculate_discount);
    }
    $self->clear_price;
}

=head2 has_price

predicate on L</price>.

=head2 has_subtotal

predicate on L</subtotal>.

=head2 has_total

predicate on L</total>.

=cut

# after cost changes we need to clear the total

after apply_cost => sub {
    my $self = shift;
    $self->clear_total;
    if ( $self->cart ) {
        $self->cart->clear_subtotal;
        $self->cart->clear_total;
    }
};

after clear_costs => sub {
    my $self = shift;
    $self->clear_total;
    if ( $self->cart ) {
        $self->cart->clear_subtotal;
        $self->cart->clear_total;
    }
};

1;
