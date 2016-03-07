package Interchange6::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

BEGIN {
    extends "Types::Standard", "Types::Common::Numeric", "Types::Common::String"
}

declare 'Cart', as InstanceOf['Interchange6::Cart'];

declare 'CartCost', as InstanceOf['Interchange6::Cart::Cost'];

declare 'CartProduct', as InstanceOf['Interchange6::Cart::Product'];

1;
__END__

=head1 NAME

Interchange6::Types - Type library for Interchange6

=head1 DESCRIPTION

A L<Type::Library> based on L<Type::Tiny> for the Interchange6 shop machine.

Includes all of the types from the following libraries plus some additional
types:

=over

=item * L<Types::Standard>

=item * L<Types::Common::Numeric>

=item * L<Types::Common::String>

=back

=cut

=head1 TYPES

=head2 Cart

InstanceOf['Interchange6::Cart']

=head2 CartCost

InstanceOf['Interchange6::Cart::Cost']

=head2 CartProduct'

InstanceOf['Interchange6::Cart::Product']
