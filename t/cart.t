#! perl -T
#
# Tests for Interchange6::Cart.

use strict;
use warnings;

use Test::More tests => 52;
use Test::Warnings qw/warning :no_end_test/;

use Interchange6::Cart;

my ($cart, $item, $name, $ret, $time);

# Get / set cart name
$cart = Interchange6::Cart->new();

$name = $cart->name;
ok($name eq 'main', $name);

$name = $cart->name('discount');
ok($name eq 'discount');

# Values for created / modified
$ret = $cart->created;
ok($ret > 0);

$ret = $cart->last_modified;
ok($ret > 0);

# Items
$cart = Interchange6::Cart->new(last_modified => 0);

$item = {};
$ret = $cart->add($item);
ok(! defined($ret));
ok(! $cart->last_modified)
    || diag "Last modified: " . $cart->last_modified;

$item->{sku} = 'ABC';
$ret = $cart->add($item);
ok(! defined($ret));
ok(! $cart->last_modified)
    || diag "Last modified: " . $cart->last_modified;

$item->{name} = 'Foobar';
$ret = $cart->add($item);
ok(! defined($ret));
ok(! $cart->last_modified)
    || diag "Last modified: " . $cart->last_modified;

$item->{price} = '42';
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);
ok($cart->last_modified > 0);
$ret = $cart->items();
ok(@$ret == 1, "Items: $ret");

# Combine items
$item = {sku => 'ABC', name => 'Foobar', price => 5};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items;
ok(@$ret == 1, "Items: $ret");

$item = {sku => 'DEF', name => 'Foobar', price => 5};
$ret = $cart->add($item);
ok(ref($ret) eq 'HASH', $cart->error);

$ret = $cart->items;
ok(@$ret == 2, "Items: $ret");

# Update item(s)
$cart->update(ABC => 2);

$ret = $cart->count;
ok($ret == 2, "Count: $ret");

$ret = $cart->quantity;
ok($ret == 3, "Quantity: $ret");

$cart->update(ABC => 1, DEF => 4);

$ret = $cart->count;
ok($ret == 2, "Count: $ret");

$ret = $cart->quantity;
ok($ret == 5, "Quantity: $ret");

$cart->update(ABC => 0);

$ret = $cart->count;
ok($ret == 1, "Count: $ret");

$ret = $cart->quantity;
ok($ret == 4, "Quantity: $ret");

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

