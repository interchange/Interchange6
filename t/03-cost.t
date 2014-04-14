#! perl -T
#
# Tests for Interchange6::Cart costs.

use strict;
use warnings;

#use Test::Most tests => 22;
use Test::Most 'die';

use Interchange6::Cart;

my ( $cart, $product, $ret );

$cart = Interchange6::Cart->new;

throws_ok(
    sub { $cart->apply_cost() },
    qr/argument to apply_cost undefined/,
    "fail apply_cost with empty args"
);

throws_ok(
    sub { $cart->apply_cost(undef) },
    qr/argument to apply_cost undefined/,
    "fail apply_cost with undef arg"
);

my $ref = { foo => 'bar' };
bless $ref, "Some::Bad::Class";

throws_ok(
    sub { $cart->apply_cost($ref) },
    qr/Supplied cost not an Interchange6::Cart::Cost : Some::Bad::Class/,
    "fail apply_cost with bad class as arg"
);

throws_ok(
    sub { $cart->apply_cost( amount => 5 ) },
    qr/Missing required arguments: name/,
    "fail apply_cost with arg amount only"
);

throws_ok(
    sub { $cart->apply_cost( name => 'fee' ) },
    qr/Missing required arguments: amount/,
    "fail apply_cost with arg amount only"
);

# fixed amount to empty cart
lives_ok( sub { $cart->apply_cost( amount => 5, name => 'fee' ) },
    "apply_cost 5 with name fee" );

cmp_ok( $cart->cost_count, '==', 1, "cost_count is 1" );

cmp_ok( $cart->costs->[0]->label, 'eq', 'fee', "cost label lazily set to fee" );

cmp_ok( $cart->total, '==', 5, "cart total is 5" );

throws_ok(
    sub { $cart->cost() },
    qr/position or name required/,
    "fail calling cost with no arg"
);

throws_ok(
    sub { $cart->cost(' ') },
    qr/Bad argument to cost:/,
    "fail calling cost with single space as arg"
);

throws_ok(
    sub { $cart->cost("I'm not there") },
    qr/Bad argument to cost:/,
    "fail calling cost with bad cost name"
);

# get cost by position
$ret = $cart->cost(0);
ok( $ret == 5, "Total: $ret" );

# get cost by name
$ret = $cart->cost('fee');
ok( $ret == 5, "Total: $ret" );

lives_ok( sub { $cart->clear_cost() }, "Clear costs" );

# relative amount to empty cart
$cart->apply_cost( name => 'tax', amount => 0.5, relative => 1 );

$ret = $cart->total;
ok( $ret == 0, "Total: $ret" );

$cart->clear_cost;

# relative amount to cart with one product
$product = { sku => 'ABC', name => 'Foobar', price => 22 };
$ret = $cart->add($product);

cmp_ok( $cart->count, '==', 1, "one product in cart" );

$cart->apply_cost( amount => 0.5, relative => 1, name => 'megatax' );

$ret = $cart->total;
ok( $ret == 33, "Total: $ret" );

$ret = $cart->cost(0);
ok( $ret == 11, "Cost: $ret" );

$ret = $cart->cost('megatax');
ok( $ret == 11, "Cost: $ret" );

$cart->clear_cost;

# relative and inclusive amount to cart with one product
$cart->apply_cost(
    amount    => 0.5,
    relative  => 1,
    inclusive => 1,
    name      => 'megatax'
);

$ret = $cart->total;
ok( $ret == 22, "Total: $ret" );

$ret = $cart->cost(0);
ok( $ret == 11, "Cost: $ret" );

$ret = $cart->cost('megatax');
ok( $ret == 11, "Cost: $ret" );

$cart->clear_cost;

done_testing;
