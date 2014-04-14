# Interchange6::Cart::Cost - Interchange6 cart cost class

package Interchange6::Cart::Cost;

use strict;
use Moo;
use Interchange6::Types;

use namespace::clean;

=head1 NAME 

Interchange6::Cart::Cost - Cart cost class for Interchange6 Shop Machine

=head1 DESCRIPTION

Cart cost class for L<Interchange6>.

=head2 ATTRIBUTES

=over 4

=item * cart_costs_id

Can be used by subclasses to tie cart cost to L<Interchange6::Schema::Result::CartCost>.

=cut

has cart_costs_id => (
    is => 'ro',
    isa => Int,
);

=item * name

Unique name is required.

=cut

has name => (
    is       => 'ro',
    isa      => AllOf [ Defined, NotEmpty, VarChar [64] ],
    required => 1,
);

=item * label

Label for display. Default is same value as label.

=cut

has label => (
    is  => 'lazy',
    isa => AllOf [ Defined, NotEmpty, VarChar [64] ],
);

=item * relative

Boolean defaults to 0. If true then L<amount> is relative to L<Cart subtotal|Intechange6::Cart/subtotal>. If false then L<amount> is an absolute cost.

=cut

has relative => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=item * inclusive

Boolean defaults to 0. If true signifies that the cost is already included in L<Product price|Interchange6::Cart::Product/price> for example to calculate the tax component for gross prices.

=cut

has inclusive => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=item * amount

Required amount of the cost. This is the absolute cost unless L<relative> is true in which case it realtive to the L<Cart subtotal|Interchange6::Cart/subtotal>. For example for a tax of 8% amount should be set to 0.08

=cut

has amount => (
    is      => 'ro',
    isa     => AllOf [ Defined, Num ],
    required => 1,
);

=back

=head1 PRIVATE METHODS

=head2 _build_label

If L<label> is not supplied then set it to the value of L<name>.

=cut

sub _build_label {
    my $self = shift;
    return $self->name;
};

1;
