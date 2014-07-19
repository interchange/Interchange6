# Interchange6::Cart::Product::Extra - Interchange6 cart product extra data class

package Interchange6::Cart::Product::Extra;

use strict;
use Moo;
use Interchange6::Types;

use namespace::clean;

=head1 NAME 

Interchange6::Cart::Product::Extra - Cart product extra data class for Interchange6 Shop Machine

=head1 DESCRIPTION

Cart product extra data class for L<Interchange6>.

=head2 ATTRIBUTES

=over 4

=item * cart_product_extra_id

Can be used by subclasses to tie extra cart product data to L<Interchange6::Schema::Result::Cart::Product::Extra>.

=cut

has cart_product_extra_id => (
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

=item * value

Required value of extra.

=cut

has value => (
    is      => 'ro',
    isa     => AllOf [ Defined, NotEmpty, VarChar [64] ],
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
