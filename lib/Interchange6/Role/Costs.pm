# Interchange6::Role::Costs - Interchange6 costs role for carts and products

package Interchange6::Role::Costs;

use Interchange6::Cart::Cost;
use Scalar::Util 'blessed';
use Moo::Role;
use MooseX::CoverableModifiers;
use MooX::HandlesVia;
use Interchange6::Types;

use namespace::clean;

=head1 ATTRIBUTES

=head2 costs

Holds an array reference of L<Interchange::Cart::Cost> items.

When called without arguments returns an array reference of all costs associated with the object. Costs are ordered according to the order they were applied.

=cut

has costs => (
    is          => 'rw',
    isa         => ArrayRef [ InstanceOf ['Interchange::Cart::Cost'] ],
    default     => sub { [] },
    handles_via => 'Array',
    handles     => {
        clear_costs => 'clear',
        cost_get    => 'get',
        cost_set    => 'set',
        cost_count  => 'count',
        _cost_push  => 'push',
        get_costs   => 'elements',
    },
    init_arg => undef,
);

=head1 METHODS

=head2 clear_costs

Removes all the costs previously applied (using apply_cost). Used typically if you have free shipping or something similar, you can clear the costs.

=head2 cost_get

Returns an element of the array of costs for the object by its index. You can also use negative index numbers, just as with Perl's core array handling.

=head2 cost_count

Returns the number of cost elements for the object.

=head2 get_costs

Returns all of the cost elements for the object as an array (not an arrayref).

=head2 apply_cost

Apply cost to object. L</apply_cost> is a generic method typicaly used for taxes, discounts, coupons, gift certificates, etc.

B<Example:> Absolute cost

Uses absolute value for amount. Amount 5 is 5 units of currency used (i.e. $5).

    $cart->apply_cost(amount => 5, name => 'shipping', label => 'Shipping');

B<Example:> Relative cost

Uses percentage instead of value for amount. Relative is a boolean value (0/1).

    Add 19% German VAT:

    $cart->apply_cost(
        amount => 0.19, name => 'tax', label => 'VAT', relative => 1
    );

    Add 10% discount (negative amount):

    $cart->apply_cost(
        amount => -0.1, name => 'discount', label => 'Discount', relative => 1
    );


B<Example:> Inclusive cost

Same as relative cost, but it assumes that tax was included in the subtotal already, and only displays it (19% of subtotal value in example). Inclusive is a boolean value (0/1).

        $cart->apply_cost(amount => 0.19, name => 'tax', label => 'Sales Tax', relative => 1, inclusive => 1);

=cut

sub apply_cost {
    my $self = shift;
    my $cost = $_[0];

    die "argument to apply_cost undefined" unless defined($cost);

    if ( blessed($cost) ) {
        die("Supplied cost not an Interchange6::Cart::Cost : " . ref($cost))
          unless $cost->isa('Interchange6::Cart::Cost');
    }
    else {
        if ( @_ % 2 ) {

            # a hashref or obj
            $cost = @_;
        }
        else {

            # hash
            $cost = {@_};
        }
        $cost = Interchange6::Cart::Cost->new( $cost );
    }

    $self->_cost_push( $cost );
}

=head2 cost

Returns particular cost by position or by name.

B<Example:> Return tax value by name

  $cart->cost('tax');

Returns value of the tax (absolute value in your currency, not percentage)

B<Example:> Return tax value by position

  $cart->cost(0);

Returns the cost that was first applied to subtotal. By increasing the number you can retrieve other costs applied.

=cut

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
                if ( $c->name eq $loc ) {
                    $cost = $c;
                }
            }
        }
    }
    else {
        die "Either position or name required as argument to cost";
    }

    if ( defined $cost ) {
        # calculate total in order to reset all costs
        my $total = $self->total;
    }
    else {
        die "Bad argument to cost: " . $loc;
    }

    return $cost->current_amount;
}

# private methods

sub _calculate {
    my ( $self, $subtotal, $costs, $display ) = @_;
    my ( @costs, $sum, $reset_costs );

    if ( ref $costs eq 'HASH' ) {
        @costs = ($costs);
    }
    elsif ( ref $costs eq 'ARRAY' ) {
        @costs = @$costs;
    }
    else {
        @costs = $self->get_costs;
        $reset_costs = 1;
    }

    $sum = 0;

    foreach my $i (0..$#costs) {

        if ( $costs[$i]->relative ) {
            $costs[$i]->current_amount($subtotal * $costs[$i]->amount);
        }
        else {
            $costs[$i]->current_amount($costs[$i]->amount);
        }

        if ( $costs[$i]->compound ) {
            $subtotal += $costs[$i]->current_amount;
        }

        unless ( $costs[$i]->inclusive ) {
            $sum += $costs[$i]->current_amount;
        }
        $self->cost_set($i, $costs[$i]) if $reset_costs;
    }

    return $sum;
}

1;
