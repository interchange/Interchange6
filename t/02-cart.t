#! perl -T
#
# Tests for Interchange6::Cart.

use strict;
use warnings;
use Data::Dumper;
use DateTime;

#use Test::More tests => 52;
use Test::More;
use Test::Warnings qw/warning :no_end_test/;
use Test::Exception;

use Interchange6::Cart;
use Interchange6::Cart::Item;

my ( $args, $cart, $item, $ret, $modified );

# create a DateTime oject for later comparison

$modified = DateTime->now;

# create a cart and change its name

lives_ok { $cart = Interchange6::Cart->new() } "Create empty cart";

isa_ok( $cart, 'Interchange6::Cart' );

ok( $cart->name eq 'main', 'Cart name is main' );

lives_ok { $ret = $cart->name('discount') } "Change cart name";
cmp_ok( $ret,        'eq', 'discount', "New name was returned" );
cmp_ok( $cart->name, 'eq', 'discount', "Cart name is discount" );

# created / modified

isa_ok( $cart->created, 'DateTime' );
cmp_ok( $cart->created, '>=', $modified, "creation time: " . $cart->created );

isa_ok( $cart->last_modified, 'DateTime' );
cmp_ok( $cart->last_modified, '>=', $modified,
    "last_modified time: " . $cart->last_modified );

# store last_modified for later

$modified = $cart->last_modified;
sleep 1;

# Items

cmp_ok( $cart->is_empty, '==', 1, "cart should be empty" );

$args = { sku => 'ABC', name => 'Foobar', price => 42 };

lives_ok { $item = Interchange6::Cart::Item->new($args) }
"create Interchange::Cart::Item";

lives_ok { $cart->add($item) } "add item to cart";

cmp_ok( $cart->count, '==', 1, "should have one item in cart" );

cmp_ok( $cart->is_empty, '==', 0, "cart should not be empty" );

cmp_ok( $cart->last_modified, '>', $modified,
    "last_modified updated: " . $cart->last_modified );

$modified = $cart->last_modified;
sleep 1;

lives_ok { $cart->clear } "clear cart";

cmp_ok( $cart->count, '==', 0, "cart count should be zero" );

cmp_ok( $cart->is_empty, '==', 1, "cart should be empty" );

cmp_ok( $cart->last_modified, '>', $modified,
    "last_modified updated: " . $cart->last_modified );

$modified = $cart->last_modified;
sleep 1;

# add has item to cart

lives_ok { $cart->add( %{$args} ) } "add item hash to cart";
cmp_ok( $cart->count, '==', 1, "should have one item in cart" );
lives_ok { $cart->clear } "clear cart";

# add has item to cart

lives_ok { $cart->add( $args ) } "add item hashref to cart";
cmp_ok( $cart->count, '==', 1, "should have one item in cart" );

# add item a second time

lives_ok { $cart->add( $args ) } "add item hashref to cart again";
cmp_ok( $cart->count, '==', 1, "should have one item in cart" );

cmp_ok( $cart->last_modified, '>', $modified,
    "last_modified updated: " . $cart->last_modified );

$modified = $cart->last_modified;
sleep 1;

lives_ok{ $cart->remove('ABC') } "Remove item from cart by sku";

cmp_ok( $cart->is_empty, '==', 1, "cart should be empty" );

cmp_ok( $cart->last_modified, '>', $modified,
    "last_modified updated: " . $cart->last_modified );

$modified = $cart->last_modified;
sleep 1;

# do some things with multiple items

lives_ok { $cart->add( $args ) } "add item hashref to cart";

cmp_ok( $cart->count, '==', 1, "should have one item in cart" );

cmp_ok($cart->items->[0]->quantity, '==', 1, "item quantity is 1");

lives_ok { $cart->add( $args ) } "add same item hashref to cart";

cmp_ok( $cart->count, '==', 1, "should have one item in cart" );

cmp_ok($cart->items->[0]->quantity, '==', 2, "item quantity is 3");

$args = { sku => 'DEF', name => 'Foo', price => 10 };

lives_ok { $cart->add( $args ) } "add second item hashref to cart";

cmp_ok($cart->items->[0]->quantity, '==', 2, "quantity of 1st item is still 2");

cmp_ok( $cart->count, '==', 2, "should have 2 items in cart" );

$args = { sku => 'GHI', name => 'Bar', price => 15 };

lives_ok { $cart->add( $args ) } "add third item hashref to cart";

cmp_ok( $cart->count, '==', 3, "should have 3 items in cart" );

cmp_ok($cart->quantity, '==', 4, "cart quantity is 4");

lives_ok { $cart->update( GHI => 7 ) } "change quantity of 3rd item to 7";

cmp_ok( $cart->count, '==', 3, "should still have 3 items in cart" );

cmp_ok($cart->items->[2]->quantity, '==', 7, "quantity of 3rd item is 7");

cmp_ok($cart->quantity, '==', 10, "cart quantity is 10");

cmp_ok( $cart->last_modified, '>', $modified,
    "last_modified updated: " . $cart->last_modified );

$modified = $cart->last_modified;
sleep 1;

# try to add empty and null items;

throws_ok { $cart->add() } qr/Missing required arg/, "try to add undef item";

cmp_ok( $cart->last_modified, '==', $modified,
    "last_modified unchanged: " . $cart->last_modified );

throws_ok { $cart->add({}) } qr/Missing required arg/, "try to add empty item";

cmp_ok( $cart->last_modified, '==', $modified,
    "last_modified unchanged: " . $cart->last_modified );

cmp_ok( $cart->count, '==', 3, "should still have 3 items in cart" );

cmp_ok( $cart->quantity, '==', 10, "cart quantity is still 10");

# remove 1st item by setting quantity to zero

lives_ok { $cart->update( ABC => 0 ) } "change quantity of 1st item to 0";

cmp_ok( $cart->count, '==', 2, "should have 2 items in cart" );

cmp_ok( $cart->quantity, '==', 8, "cart quantity is 8");


done_testing;
__END__

# Cart removal
$cart = Interchange6::Cart->new(run_hooks => sub {
    my ($hook, $cart, $item) = @_;

    if ($hook eq 'before_cart_remove' && $item->{sku} eq '123') {
    $item->{error} = 'Item not removed due to hook.';
    }
              });

$item = {sku => 'DEF', name => 'Foobar', price => 5};
$ret = $cart->add($item);

$item = {sku => '123', name => 'Foobar', price => 5};
$ret = $cart->add($item);

$ret = $cart->remove('123');
ok($cart->error eq 'Item not removed due to hook.', "Cart Error: " . $cart->error);

$ret = $cart->items;
ok(@$ret == 2, "Items: $ret");

$ret = $cart->remove('DEF');
ok(defined($ret), "Item DEF removed from cart.");

$ret = $cart->items;
ok(@$ret == 1, "Items: $ret");

# 
# Calculating total
$cart->clear;
$ret = $cart->total;
ok($ret == 0, "Total: $ret");

$item = {sku => 'GHI', name => 'Foobar', price => 2.22, quantity => 3};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->total;
ok($ret == 6.66, "Total: $ret");

$item = {sku => 'KLM', name => 'Foobar', price => 3.34, quantity => 1};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->total;
ok($ret == 10, "Total: $ret");

# Hooks
$cart = Interchange6::Cart->new(run_hooks => sub {
    my ($hook, $cart, $item) = @_;

    if ($hook eq 'before_cart_add' && $item->{price} > 3) {
	$item->{error} = 'Test error';
    }
			  });

$item = {sku => 'KLM', name => 'Foobar', price => 3.34, quantity => 1};
$ret = $cart->add($item);

$ret = $cart->items;
ok(@$ret == 0, "Items: $ret");

ok($cart->error eq 'Test error', "Cart error: " . $cart->error);

# Seed
$cart = Interchange6::Cart->new();
$cart->seed([{sku => 'ABC', name => 'ABC', price => 2, quantity => 1},
	     {sku => 'ABCD', name => 'ABCD', price => 3, quantity => 2},
	    ]);

$ret = $cart->items;
ok(@$ret == 2, "Items: $ret");

$ret = $cart->count;
ok($ret == 2, "Count: $ret");

$ret = $cart->quantity;
ok($ret == 3, "Quantity: $ret");

$ret = $cart->total;
ok($ret == 8, "Total: $ret");

$cart->clear;

$ret = $cart->count;
ok($ret == 0, "Count: $ret");

$ret = $cart->quantity;
ok($ret == 0, "Quantity: $ret");

# users id
$cart = Interchange6::Cart->new();

$ret = $cart->users_id;
ok (! defined($ret), "Users id of anonymous user");

$ret = $cart->users_id(100);
ok ($ret eq '100', "Return value of users_id setter");

$ret = $cart->users_id;
ok ($ret eq '100', "Value of users_id after setting it to 100");

$cart = Interchange6::Cart->new(run_hooks => sub {
    my ($hook, $object, $data) = @_;

    if ($hook eq 'before_cart_set_users_id') {
        warn "Testing before_set_users_id hook with $data->{users_id}.\n";
    }

    if ($hook eq 'after_cart_set_users_id') {
        warn "Testing after_set_users_id hook with $data->{users_id}.\n";
    }
});

my $warns = warning {$ret = $cart->users_id(200)};

ok (ref($warns) eq 'ARRAY' && @$warns == 2,
    "Test number of warnings from set_users_id_hook");

ok ($warns->[0] eq "Testing before_set_users_id hook with 200.\n",
    "Test warning from before_set_users_id hook.")
    || diag "Warning: $warns->[0].";

ok ($warns->[1] eq "Testing after_set_users_id hook with 200.\n",
     "Test warning from after_set_users_id hook.")
    || diag "Warning: $warns->[1].";

# sessions id
$cart = Interchange6::Cart->new();

$ret = $cart->sessions_id;
ok (! defined($ret), "Users id of anonymous user");

$ret = $cart->sessions_id('323460431348215171797029562762075811');
ok ($ret eq '323460431348215171797029562762075811', "Return value of sessions_id setter");

$ret = $cart->sessions_id;
ok ($ret eq '323460431348215171797029562762075811', "Value of sessions_id after setting it to 323460431348215171797029562762075811");

$cart = Interchange6::Cart->new(run_hooks => sub {
    my ($hook, $object, $data) = @_;

    if ($hook eq 'before_cart_set_sessions_id') {
        warn "Testing before_set_sessions_id hook with $data->{sessions_id}.\n";
    }

    if ($hook eq 'after_cart_set_sessions_id') {
        warn "Testing after_set_sessions_id hook with $data->{sessions_id}.\n";
    }
});

$warns = warning {$ret = $cart->sessions_id('513457188818705086798161933370395265')};

ok (ref($warns) eq 'ARRAY' && @$warns == 2,
    "Test number of warnings from set_sessions_id_hook");

ok ($warns->[0] eq "Testing before_set_sessions_id hook with 513457188818705086798161933370395265.\n",
    "Test warning from before_set_sessions_id hook.")
    || diag "Warning: $warns->[0].";

ok ($warns->[1] eq "Testing after_set_sessions_id hook with 513457188818705086798161933370395265.\n",
     "Test warning from after_set_sessions_id hook.")
    || diag "Warning: $warns->[1].";

