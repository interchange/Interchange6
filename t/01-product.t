#! perl -T
#
# Tests for Interchange6::Cart::Product

use strict;
use warnings;

use Test::More tests => 38;
use Test::Warnings qw/warning :no_end_test/;
use Test::Exception;

use Interchange6::Cart::Product;

my ( $args, $product, $name, $ret, $time );

# empty product

$args = {};

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/Missing.+arguments/, "create Product with no args";

# good product with no quantity

$args = { sku => 'ABC', name => 'Foobar', price => 42 };

lives_ok { $product = Interchange6::Cart::Product->new($args) }
"create Product with good sku, name and price";

isa_ok( $product, 'Interchange6::Cart::Product' );

is( $product->quantity, 1, "default quantity is 1" );

# a larger quantity

$args->{quantity} = 4;

lives_ok { $product = Interchange6::Cart::Product->new($args) }
"create Product with good sku, name, price and quantity";

isa_ok( $product, 'Interchange6::Cart::Product' );

is( $product->quantity, 4, "quantity is 4" );

# undef sku

$args->{sku} = undef;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/sku.+not defined/,
  "create Product with undef sku";

# empty sku

$args->{sku} = '';

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/sku.+contain some non-space/, "create Product with empty sku";

# sku > 32 chars

$args->{sku} = 'X' x 33;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/sku.+length.+32/,
  "create Product with over-long sku";

# no sku

delete $args->{sku};

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/Missing.+arg.+sku/, "create Product with no sku";

# undef name

$args->{sku}  = 'ABC';
$args->{name} = undef;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/name.+not defined/,
  "create Product with undef name";

# empty name

$args->{name} = '';

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/name.+contain some non-space/, "create Product with empty name";

# name > 255 chars

$args->{name} = 'X' x 256;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/name.+length.+255/, "create Product with over-long name";

# no name

delete $args->{name};

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/Missing.+arg.+name/, "create Product with no name";

# negative quantity

$args->{name}     = 'Foobar';
$args->{quantity} = -2;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/quantity.+not a positive num/, "create Product with negative quantity";

# non-integer quantity

$args->{quantity} = 2.5;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/quantity.+not an integer/, "create Product with non-integer quantity";

# undef price

$args->{quantity} = 4;
$args->{price}    = undef;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/price.+not defined/,
  "create Product with undef price";

# empty price

$args->{price} = '';

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/price.+is not a positive num/, "create Product with empty price";

# negative price

$args->{price} = -5;

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/price.+is not a positive num/, "create Product with negative price";

# no price

delete $args->{price};

throws_ok { $product = Interchange6::Cart::Product->new($args) }
qr/Missing.+arg.+price/, "create Product with no price";

# Now test setters & getters

# start by checking that an initial product is good

$args = { sku => 'ABC', name => 'Foobar', price => 42, quantity => 4 };

lives_ok { $product = Interchange6::Cart::Product->new($args) }
"create clean product";

isa_ok( $product, 'Interchange6::Cart::Product' );

is( $product->sku,      'ABC',    "sku is ABC" );
is( $product->name,     'Foobar', "name is Foobar" );
is( $product->price,    42,       "price is 42" );
is( $product->quantity, 4,        "quantity is 4" );

# try to change sku

dies_ok { $product->sku('new sku') } "should not be able to change sku";
is( $product->sku, 'ABC', "sku is still ABC" );

# try to change name

dies_ok { $product->name('new name') } "should not be able to change name";
is( $product->name, 'Foobar', "name is still Foobar" );

# try to change price

dies_ok { $product->price(45) } "should not be able to change price";
is( $product->price, 42, "price is still 42" );

# change quantity

lives_ok { $ret = $product->quantity(20) } "change quantity";
is( $ret,               20, "quantity 20 is returned" );
is( $product->quantity, 20, "product quantity is 20" );

# bad quantity

throws_ok { $ret = $product->quantity(-2) } qr/quantity.+is not a positive num/,
  "try to set negative quantity";

is( $product->quantity, 20, "product quantity is still 20" );

