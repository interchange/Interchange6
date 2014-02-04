# Interchange6::Cart - Interchange6 cart class

package Interchange6::Cart;

use strict;
use Data::Dumper;
use DateTime;
use Interchange6::Cart::Item;
use Scalar::Util 'blessed';
use Moo;
use MooX::HandlesVia;
use MooX::Types::MooseLike::Base qw(:all);
use Interchange6::Types qw(HasChars VarChar);

use namespace::clean;

use constant CART_DEFAULT => 'main';

=head1 NAME 

Interchange6::Cart - Cart class for Interchange6 Shop Machine

=head1 DESCRIPTION

Generic cart class for L<Interchange6>.

=head2 CART ATTRIBUTES AND METHODS

=over 11

=item cache_subtotal

=cut

has cache_subtotal => (
    is => 'rw',
    isa => Bool,
    default => 1,
);

=item cache_total

=cut

has cache_total => (
    is => 'rw',
    isa => Bool,
    default => 1,
);

=item costs

Costs such as tax and shipping

=cut

has costs => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
);

=item created

Time cart was created (DateTime object).

Read-only attribute.
=cut

has created => (
    is      => 'ro',
    isa     => InstanceOf['DateTime'],
    default => sub { DateTime->now },
);

=item error

Last error

=cut

has error => (
    is  => 'rwp',
    isa => Str,
    default => '',
);

=item items

Arrayref of Interchange::Cart::Item(s)

=cut

has items => (
    is  => 'rw',
    isa => ArrayRef [ InstanceOf ['Interchange::Cart::Item'] ],
    default => sub { [] },
    handles_via => 'Array',
    handles => {
        count    => 'count',
        is_empty => 'is_empty',
    },
);

=item last_modified

Time cart was last modified (DateTime object)

=cut

has last_modified => (
    is      => 'rwp',
    isa     => InstanceOf['DateTime'],
    default => sub { DateTime->now },
);

=item modifiers

=cut

has modifiers => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

=item name

Name of cart

=cut

has name => (
    is      => 'rw',
    isa     => AllOf [ Defined, HasChars, VarChar [255] ],
    default => CART_DEFAULT,
);

=item subtotal

Current cart subtotal excluding costs

=cut

has subtotal => (
    is      => 'rwp',
    isa     => Num,
    default => 0,
);

=item total

Current cart total including costs

=cut

has total => (
    is      => 'rwp',
    isa     => Num,
    default => 0,
);

=back

=head2 add $item

Add item to the cart. Returns item in case of success.

The item is an L<Interchange6::Cart::Item> or a hash (reference) which is subject to the following conditions:

=over 4

=item sku

Item identifier is required.

=item name

Item name is required.

=item quantity

Item quantity is optional and has to be a natural number greater
than zero. Default for quantity is 1.

Item price is required and a positive number.

Price is required, because you want to maintain the price that was valid at the time of adding to the cart. Should the price in the shop change in the meantime, it will maintain this price. If you would like to update the pages, you have to do it before loading the cart page on your shop.


B<Example:> Add 5 BMX2012 products to the cart

    $cart->add( sku => 'BMX2012', name => 'BMX bike', quantity => 5,
        price => 200);

B<Example:> Add a BMX2012 product to the cart.

    $cart->add( sku => 'BMX2012', name => 'BMX bike', price => 200);

=back

=cut

sub add {
    my $self = shift;
    my $item = $_[0];
    my $ret;

    # reset error

    $self->_set_error('');

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

    my $args = { sku => 'ABC', name => 'Foobar', price => 42 };

        $item = 'Interchange6::Cart::Item'->new( $args );

        unless ( blessed($item) && $item->isa('Interchange6::Cart::Item') ) {
            $self->_set_error("failed to create item: $_");
            return;
        }
    }

    # $item is now an Interchange6::Cart::Item

    # cart may already contain an item with the same sku
    # if so then we add quantity to existing item otherwise we add new item

    unless ( $ret = $self->_combine($item) ) {
        push @{ $self->items }, $item;
        $self->_set_last_modified(DateTime->now);
    }

    return $item;
}

sub _combine {
    my ( $self, $item ) = @_;

  ITEMS: for my $cartitem ( @{ $self->{items} } ) {
        if ( $item->sku eq $cartitem->sku ) {
            for my $mod ( @{ $self->modifiers } ) {

                # FIXME: modifiers needs to be handled
                #next ITEMS unless($item->{$mod} eq $cartitem->{$mod});
            }

            $cartitem->quantity( $cartitem->quantity + $item->quantity );
            $item->quantity($cartitem->quantity);

            return 1;
        }
    }

    return 0;
}

=head2 update


=cut

sub update {
}

=head2 clear

Removes all items from the cart.

=cut

sub clear {
    my ($self) = @_;

    # run hook before clearing the cart
    $self->_run_hook('before_cart_clear', $self);

    $self->items([]);

    # run hook after clearing the cart
    $self->_run_hook('after_cart_clear', $self);

    # reset subtotal/total
    $self->_set_subtotal(0);
    $self->_set_total(0);
    $self->cache_subtotal(1);
    $self->cache_total(1);

    $self->_set_last_modified(DateTime->now);

    return;
}

sub _run_hook {
    my ($self, $name, @args) = @_;
    my $ret;

    if ($self->{run_hooks}) {
    $ret = $self->{run_hooks}->($name, @args);
    }

    return $ret;
}

=head1 AUTHORS

Stefan Hornburg (Racke), <racke@linuxia.de>
Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2013 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
