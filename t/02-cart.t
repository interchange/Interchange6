#! perl -T
#
# Tests for Interchange6::Cart.

use strict;
use warnings;
use Data::Dumper;

use Test::Most 'die';
use Test::Warnings qw/warning :no_end_test/;

use Interchange6::Cart;
use Interchange6::Cart::Product;
use Interchange6::Hook;

my ( $args, $cart, $product, $ret, $hook );

# create a cart and change its name

lives_ok { $cart = Interchange6::Cart->new() } "Create empty cart";

isa_ok( $cart, 'Interchange6::Cart' );

ok( $cart->name eq 'main', 'Cart name is main' );

lives_ok { $ret = $cart->rename('discount') } "Change cart name";
cmp_ok( $ret,        'eq', 'discount', "New name was returned" );
cmp_ok( $cart->name, 'eq', 'discount', "Cart name is discount" );

# Products

cmp_ok( $cart->is_empty, '==', 1, "cart should be empty" );

$args = { sku => 'ABC', name => 'Foobar', price => 42 };

lives_ok { $product = Interchange6::Cart::Product->new($args) }
"create Interchange::Cart::Product";

cmp_ok( $cart->subtotal, '==', 0, "Check subtotal" );
cmp_ok( $cart->total,    '==', 0, "Check total" );

throws_ok( sub { $cart->add(Interchange6::Cart->new) },
   qr/product argument is not an Interchange6::Cart::Product/,
   "Fail to add Cart to Cart"
);

lives_ok { $cart->add($product) } "add product to cart";

cmp_ok( $cart->count, '==', 1, "should have one product in cart" );

cmp_ok( $cart->is_empty, '==', 0, "cart should not be empty" );

cmp_ok( $cart->subtotal, '==', 42, "Check subtotal" );
cmp_ok( $cart->total,    '==', 42, "Check total" );

lives_ok { $cart->clear } "clear cart";

cmp_ok( $cart->count, '==', 0, "cart count should be zero" );

cmp_ok( $cart->is_empty, '==', 1, "cart should be empty" );

# add has product to cart

lives_ok { $cart->add( %{$args} ) } "add product hash to cart";
cmp_ok( $cart->count, '==', 1, "should have one product in cart" );
lives_ok { $cart->clear } "clear cart";

# add has product to cart

lives_ok { $cart->add($args) } "add product hashref to cart";
cmp_ok( $cart->count, '==', 1, "should have one product in cart" );

# add product a second time

lives_ok { $cart->add($args) } "add product hashref to cart again";
cmp_ok( $cart->count, '==', 1, "should have one product in cart" );

lives_ok { $cart->remove('ABC') } "Remove product from cart by sku";

cmp_ok( $cart->is_empty, '==', 1, "cart should be empty" );

# do some things with multiple products

lives_ok { $cart->add($args) } "add product hashref to cart";

cmp_ok( $cart->count, '==', 1, "should have one product in cart" );

cmp_ok( $cart->products->[0]->quantity, '==', 1, "product quantity is 1" );

lives_ok { $cart->add($args) } "add same product hashref to cart";

cmp_ok( $cart->count, '==', 1, "should have one product in cart" );

cmp_ok( $cart->products->[0]->quantity, '==', 2, "product quantity is 2" );

$args = { sku => 'DEF', name => 'Foo', price => 10 };

lives_ok { $cart->add($args) } "add second product hashref to cart";

cmp_ok( $cart->products->[0]->quantity,
    '==', 2, "quantity of 1st product is still 2" );

cmp_ok( $cart->count, '==', 2, "should have 2 products in cart" );

$args = { sku => 'GHI', name => 'Bar', price => 15 };

lives_ok { $cart->add($args) } "add third product hashref to cart";

cmp_ok( $cart->count, '==', 3, "should have 3 products in cart" );

cmp_ok( $cart->quantity, '==', 4, "cart quantity is 4" );

lives_ok { $cart->update( GHI => 7 ) } "change quantity of 3rd product to 7";

cmp_ok( $cart->count, '==', 3, "should still have 3 products in cart" );

cmp_ok( $cart->products->[2]->quantity,
    '==', 7, "quantity of 3rd product is 7" );

cmp_ok( $cart->quantity, '==', 10, "cart quantity is 10" );

cmp_ok( $cart->subtotal, '==', 199, "cart subtotal is 199" );
cmp_ok( $cart->total,    '==', 199, "cart total is 199" );

# try to add empty and null products;

throws_ok { $cart->add() } qr/Missing required arg/, "try to add undef product";

throws_ok { $cart->add( {} ) } qr/Missing required arg/,
  "try to add empty product";

cmp_ok( $cart->count, '==', 3, "should still have 3 products in cart" );

cmp_ok( $cart->quantity, '==', 10, "cart quantity is still 10" );

# remove 1st product by setting quantity to zero

lives_ok { $cart->update( ABC => 0 ) } "change quantity of 1st product to 0";

cmp_ok( $cart->count, '==', 2, "should have 2 products in cart" );

cmp_ok( $cart->quantity, '==', 8, "cart quantity is 8" );

# hook testing

# Cart removal - start with a nice clean cart

lives_ok { $cart = Interchange6::Cart->new } "Create new cart";

$product = { sku => 'DEF', name => 'Foobar', price => 5 };
lives_ok { $cart->add($product) } "add product";

cmp_ok( $cart->count, '==', 1, "1 product in cart" );

lives_ok( sub { $cart->clear }, "cart clear" );

cmp_ok( $cart->count, '==', 0, "0 products in cart" );

cmp_ok($cart->name, 'eq', 'main', "cart name is main");

lives_ok { $cart->rename("bananas") } "Change cart name to bananas";

cmp_ok($cart->name, 'eq', 'bananas', "cart name is bananas");

lives_ok { $cart->rename("main") } "Change cart name to main";

cmp_ok($cart->name, 'eq', 'main', "cart name is main");

# Seed

lives_ok { $cart = Interchange6::Cart->new } "Create new cart";

lives_ok {
    $cart->seed(
        [
            { sku => 'ABC',  name => 'ABC',  price => 2, quantity => 1 },
            { sku => 'ABCD', name => 'ABCD', price => 3, quantity => 2 },
        ]
    );
}
"Seed cart with 2 products";

cmp_ok( $cart->count, '==', 2, "Should be 2 products in cart" );

cmp_ok( $cart->quantity, '==', 3, "Quantity should be 3" );

cmp_ok( $cart->total, '==', 8, "Total should be 8" );

# users id

lives_ok { $cart = Interchange6::Cart->new } "Create new cart";

$ret = $cart->users_id;
ok( !defined($ret), "Users id of anonymous user" );

$ret = $cart->set_users_id(100);
ok( $ret eq '100', "Return value of users_id setter" );

$ret = $cart->users_id;
ok( $ret eq '100', "Value of users_id after setting it to 100" );

# sessions id
$cart = Interchange6::Cart->new();

$ret = $cart->sessions_id;
ok( !defined($ret), "Users id of anonymous user" );

$ret = $cart->set_sessions_id('323460431348215171797029562762075811');
ok(
    $ret eq '323460431348215171797029562762075811',
    "Return value of sessions_id setter"
);

$ret = $cart->sessions_id;
ok(
    $ret eq '323460431348215171797029562762075811',
"Value of sessions_id after setting it to 323460431348215171797029562762075811"
);

done_testing;
