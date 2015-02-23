# Interchange6::Cart::Product - Interchange6 cart product class

package Interchange6::Cart::Product;

use strict;
use Moo;
use MooX::HandlesVia;
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

=head2 canonical_sku

If this product is a variant of a "parent" product then C<canonical_sku>
is the sku of the parent product.

=cut

has canonical_sku => (
    is        => 'ro',
    predicate => 'is_variant',
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

=head2 extra

Hash reference of extra things the cart product might want to store such as:

=over

=item * variant attributes in order to be able to change variant within cart

=item * simple attributes to allow display of them within cart

=back

=cut

has extra => (
    is          => 'ro',
    isa         => HashRef,
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        get_extra     => 'get',
        set_extra     => 'set',
        delete_extra  => 'delete',
        keys_extra    => 'keys',
        clear_extra   => 'clear',
        exists_extra  => 'exists',
        defined_extra => 'defined',
    },
);

=head1 METHODS

=head2 L</extra> methods

=over

=item * get_extra($key, $key2, $key3...)

See L<Data::Perl::Role::Collection::Hash/get>

=item * set_extra($key => $value, $key2 => $value2...)

See L<Data::Perl::Role::Collection::Hash/set>

=item * delete_extra($key, $key2, $key3...)

See L<Data::Perl::Role::Collection::Hash/set>

=item * keys_extra

See L<Data::Perl::Role::Collection::Hash/keys>

=item * clear_extra

See L<Data::Perl::Role::Collection::Hash/clear>

=item * exists_extra($key)

See L<Data::Perl::Role::Collection::Hash/exists>

=item * defined_extra($key)

See L<Data::Perl::Role::Collection::Hash/defined>

=back


=head2 L</subtotal> methods

=over

=item * clear_subtotal

Clears L</subtotal>.

=item * has_subtotal

predicate on L</subtotal>.

=back


=head2 L</total> methods

=over

=item * clear_total

Clears L</total>.

=item * has_total

predicate on L</total>.


=item * is_variant

predicate on L</canonical_sku>.

=item * is_canonical

inverse of L</is_variant>.

=cut

sub is_canonical {
    return shift->is_variant ? 0 : 1;
}

=back

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
