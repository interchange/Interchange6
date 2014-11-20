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

=head2 name

Product name is required.

=cut

has name => (
    is       => 'ro',
    isa      => AllOf [ Defined, NotEmpty, VarChar [255] ],
    required => 1,
);

=head2 price

Product price is required and a positive number or zero.

Price is required, because you want to maintain the price that was valid at the time of adding to the cart. Should the price in the shop change in the meantime, it will maintain this price.

=cut

has price => (
    is        => 'ro',
    isa       => AnyOf [ PositiveNum, Zero ],
    required  => 1,
);

=head2 selling_price

Selling price is the price after group pricing, tier pricing or promotional discounts have been applied. If it is not set then it defaults to L</price>.

=cut

has selling_price => (
    is        => 'rw',
    isa       => Num,
    builder   => 1,
    lazy      => 1,
);

sub _build_selling_price {
    my $self = shift;
    return $self->price;
}

=head2 discount_percent

This is the integer discount percentage calculated from the difference
between L</price> and L</selling_price>. This attribute should not normally
be set since as it is a calculated value.

=cut

has discount_percent => (
    is => 'lazy',
);

sub _build_discount_percent {
    my $self = shift;
    return 0 if $self->price == $self->selling_price;
    return int( ( $self->price - $self->selling_price ) / $self->price * 100 );
}

=head2 quantity

Product quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

=cut

has quantity => (
    is      => 'ro',
    isa     => AllOf [ PositiveNum, Int ],
    default => 1,
    writer  => 'set_quantity',
);

after quantity => sub {
    my $self = shift;
    $self->clear_subtotal;
    $self->clear_total;
};

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
    return sprintf( "%.2f", $self->selling_price * $self->quantity);
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

=head2 clear_subtotal

Clears L</subtotal>.

=head2 clear_total

Clears L</total>.

=head2 has_subtotal

predicate on L</subtotal>.

=head2 has_total

predicate on L</total>.

=cut

# after cost changes we need to clear the total as well as cart subtotal/total

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
