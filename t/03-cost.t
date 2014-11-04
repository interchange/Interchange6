#! perl -T
#
# Tests for Interchange6::Cart costs.

use strict;
use warnings;

use Data::Dumper;
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

lives_ok( sub { $cart->clear_costs() }, "Clear costs" );

# relative amount to empty cart
$cart->apply_cost( name => 'tax', amount => 0.5, relative => 1 );

lives_ok( sub { $ret = $cart->total }, "get cart total" );
ok( $ret == 0, "Total: $ret" );

lives_ok( sub { $cart->clear_costs }, "Clear costs" );

# relative amount to cart with one product
$product = { sku => 'ABC', name => 'Foobar', price => 22 };
lives_ok( sub { $ret = $cart->add($product) }, "add product ABC" );

cmp_ok( $cart->count, '==', 1, "one product in cart" );

$cart->apply_cost( amount => 0.5, relative => 1, name => 'megatax' );

$ret = $cart->total;
ok( $ret == 33, "Total: $ret" );

$ret = $cart->cost(0);
ok( $ret == 11, "Cost: $ret" );

$ret = $cart->cost('megatax');
ok( $ret == 11, "Cost: $ret" );

$cart->clear_costs;

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

lives_ok( sub { $cart->apply_cost(amount => 12.34, name => 'shipping') },
    "add 12.34 shipping" );
lives_ok( sub { $cart->apply_cost(amount => 0, name => 'handling') },
    "add zero cost handling" );
cmp_ok( $cart->cost('shipping'), '==', 12.34, "shipping cost is 12.34" );
cmp_ok( $cart->cost('handling'), '==', 0, "handling cost is 0" );

$cart->clear;
$cart->clear_costs;

# product costs...

$product = { sku => 'ABC', name => 'Foobar', price => 22, quantity => 2 };
lives_ok( sub { $product = $cart->add($product) }, "Add 2 x product ABC to cart" );
cmp_ok( $product->selling_price, '==', 22, "product selling_price is 22" );
cmp_ok( $product->subtotal, '==', 44, "product subtotal is 44" );
cmp_ok( $product->total, '==', 44, "product total is 44" );
cmp_ok( $cart->subtotal, '==', 44, "cart subtotal is 44" );
cmp_ok( $cart->total, '==', 44, "cart total is 44" );

lives_ok(
    sub {
        $product->apply_cost(
            amount   => 0.18,
            name     => 'tax',
            label    => 'VAT',
            relative => 1,
        )
    }, "Add 18% VAT to discounted product"
);
ok( $product->has_subtotal, "product subtotal has not been cleared" );
ok( !$product->has_total, "product total has been cleared" );
cmp_ok( $product->subtotal, '==', 44, "product subtotal is 44" );
cmp_ok( $product->total, '==', 51.92, "product total is 51.92" );
cmp_ok( $product->cost('tax'), '==', 7.92, "product tax is 7.92" );
cmp_ok( $cart->subtotal, '==', 51.92, "cart subtotal is 51.92" );
cmp_ok( $cart->total, '==', 51.92, "cart total is 51.92" );

my $product2 = { sku => 'DEF', name => 'Banana', price => 33, quantity => 3 };
lives_ok( sub { $product2 = $cart->add($product2) }, "Add 3 x product DEF to cart" );
ok( !$product2->has_subtotal, "product subtotal is not set" );
ok( !$product2->has_total, "product total is not set" );
ok( !$cart->has_subtotal, "cart subtotal is not set" );
ok( !$cart->has_total, "cart total is not set" );
cmp_ok( $product2->selling_price, '==', 33, "product selling_price is 33" );
cmp_ok( $product2->subtotal, '==', 99, "product subtotal is 99" );
cmp_ok( $product2->total, '==', 99, "product total is 99" );
cmp_ok( $cart->subtotal, '==', 150.92, "cart subtotal is 150.92" );
cmp_ok( $cart->total, '==', 150.92, "cart total is 150.92" );

done_testing;
