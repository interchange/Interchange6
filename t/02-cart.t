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

lives_ok { $ret = $cart->name('discount') } "Change cart name";
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

lives_ok ( sub {
    $hook = Interchange6::Hook->new(
        name => 'bad_hook',
        code => sub {
            my $cart = shift;
        }
    );
},
"Create bad_hook");

throws_ok( sub { $cart->add_hook($hook) }, qr/add_hook failed/,
    "fail to add bad_hook" );

# before_cart_clear hook

$product = { sku => 'DEF', name => 'Foobar', price => 5 };
lives_ok { $cart->add($product) } "add product";

cmp_ok( $cart->count, '==', 1, "1 product in cart" );

lives_ok ( sub {
    $hook = Interchange6::Hook->new(
        name => 'before_cart_clear',
        code => sub {
            die 'some failure';
        }
    );
},
"Create before_cart_clear hook" );

lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

throws_ok( sub { $cart->clear }, qr/some failure/, "cart clear" );

cmp_ok( $cart->count, '==', 1, "still 1 product in cart" );

lives_ok( sub { $cart->replace_hook('before_cart_clear', undef ) },
    "remove hook"
);

lives_ok( sub { $cart->clear }, "cart clear" );

cmp_ok( $cart->count, '==', 0, "0 products in cart" );

# before_cart_rename hook

cmp_ok($cart->name, 'eq', 'main', "cart name is main");

lives_ok {
    $hook = Interchange6::Hook->new(
        name => 'before_cart_rename',
        code => sub {
            my ($cart, $old_name, $new_name) = @_;
            if ( $new_name eq 'not_allowed' ) {
                die 'Cart rename failed due to hook';
            }
        }
    );
}
"Create before_cart_rename hook for name eq not_allowed";

lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

lives_ok { $cart->name("bananas") } "Change cart name to bananas";

cmp_ok($cart->name, 'eq', 'bananas', "cart name is bananas");

throws_ok(
    sub { $cart->name("not_allowed") },
    qr/Cart rename failed due to hook/,
    "Change cart name to not_allowed"
);

cmp_ok($cart->name, 'eq', 'bananas', "cart name is bananas");

lives_ok( sub { $cart->replace_hook('before_cart_rename', undef ) },
    "remove hook"
);

lives_ok { $cart->name("not_allowed") } "Change cart name to not_allowed";

cmp_ok($cart->name, 'eq', 'not_allowed', "cart name is not_allowed");

lives_ok { $cart->name("main") } "Change cart name to main";

cmp_ok($cart->name, 'eq', 'main', "cart name is main");

# before_cart_add_validate hook

lives_ok( sub {
    $hook = Interchange6::Hook->new(
        name => 'before_cart_add_validate',
        code => sub {
            die 'general error';
        }
    );
},
"Create before_cart_add_validate hook");

lives_ok( sub { $cart->add_hook($hook) }, "Add the hook to the cart" );

$product = { sku => 'KLM', name => 'Foobar', price => 3, quantity => 1 };
throws_ok ( sub { $cart->add($product) }, qr/general error/, "Hooked");

lives_ok( sub { $cart->replace_hook('before_cart_add_validate', undef ) },
    "remove hook"
);

# before_cart_add hook

lives_ok {
    $hook = Interchange6::Hook->new(
        name => 'before_cart_add',
        code => sub {
            my ( $cart, $product ) = @_;
            if ( $product->price > 3 ) {
                die 'Product not added due to hook.';
            }
        }
    );
}
"Create before_cart_add hook for price > 3";

lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

$product = { sku => 'KLM', name => 'Foobar', price => 3, quantity => 1 };
lives_ok { $cart->add($product) } "add product with price = 3";

cmp_ok( $cart->count, '==', 1, "1 product in cart" );

$product = { sku => 'DEF', name => 'Foobar', price => 3.34, quantity => 1 };

throws_ok(
    sub { $cart->add($product) },
    qr/Product not added due to hook/,
    "add product with price = 3.34"
);

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

$ret = $cart->users_id(100);
ok( $ret eq '100', "Return value of users_id setter" );

$ret = $cart->users_id;
ok( $ret eq '100', "Value of users_id after setting it to 100" );

lives_ok {
    $hook = Interchange6::Hook->new(
        name => 'before_cart_set_users_id',
        code => sub {
            my ( $cart, $data ) = @_;
            warn "Testing before_set_users_id hook with $data->{users_id}.\n";
        }
    );
}
"create hook";
lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

lives_ok {
    $hook = Interchange6::Hook->new(
        name => 'after_cart_set_users_id',
        code => sub {
            my ( $cart, $data ) = @_;
            warn "Testing after_set_users_id hook with $data->{users_id}.\n";
        }
    );
}
"create hook";
lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

my $warns = warning { $ret = $cart->users_id(200) };

ok(
    ref($warns) eq 'ARRAY' && @$warns == 2,
    "Test number of warnings from set_users_id_hook"
);

ok( $warns->[0] eq "Testing before_set_users_id hook with 200.\n",
    "Test warning from before_set_users_id hook." )
  || diag "Warning: $warns->[0].";

ok( $warns->[1] eq "Testing after_set_users_id hook with 200.\n",
    "Test warning from after_set_users_id hook." )
  || diag "Warning: $warns->[1].";

# sessions id
$cart = Interchange6::Cart->new();

$ret = $cart->sessions_id;
ok( !defined($ret), "Users id of anonymous user" );

$ret = $cart->sessions_id('323460431348215171797029562762075811');
ok(
    $ret eq '323460431348215171797029562762075811',
    "Return value of sessions_id setter"
);

$ret = $cart->sessions_id;
ok(
    $ret eq '323460431348215171797029562762075811',
"Value of sessions_id after setting it to 323460431348215171797029562762075811"
);

lives_ok {
    $hook = Interchange6::Hook->new(
        name => 'before_cart_set_sessions_id',
        code => sub {
            my ( $cart, $data ) = @_;
            warn
"Testing before_set_sessions_id hook with $data->{sessions_id}.\n";
        }
    );
}
"create hook";
lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

lives_ok {
    $hook = Interchange6::Hook->new(
        name => 'after_cart_set_sessions_id',
        code => sub {
            my ( $cart, $data ) = @_;
            warn
              "Testing after_set_sessions_id hook with $data->{sessions_id}.\n";
        }
    );
}
"create hook";
lives_ok { $cart->add_hook($hook) } "Add the hook to the cart";

$warns =
  warning { $ret = $cart->sessions_id('513457188818705086798161933370395265') };

ok( ref($warns) eq 'ARRAY' && @$warns == 2,
    "Test number of warnings from set_sessions_id_hook" );

ok(
    $warns->[0] eq
"Testing before_set_sessions_id hook with 513457188818705086798161933370395265.\n",
    "Test warning from before_set_sessions_id hook."
) || diag "Warning: $warns->[0].";

ok(
    $warns->[1] eq
"Testing after_set_sessions_id hook with 513457188818705086798161933370395265.\n",
    "Test warning from after_set_sessions_id hook."
) || diag "Warning: $warns->[1].";

done_testing;
