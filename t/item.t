#! perl -T
#
# Tests for Interchange6::Cart::Item

use strict;
use warnings;

use Test::More tests => 21;
use Test::Warnings qw/warning :no_end_test/;
use Test::Exception;

use Interchange6::Cart::Item;

my ( $args, $item, $name, $ret, $time );

# empty item

$args = {};

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/Missing.+arguments/, "create Item with no args";

# good item with no quantity

$args = { sku => 'ABC', name => 'Foobar', price => 42 };

lives_ok { $item = Interchange6::Cart::Item->new($args) }
"create Item with good sku, name and price";

isa_ok( $item, 'Interchange6::Cart::Item' );

is( $item->quantity, 1, "default quantity is 1" );

# a larger quantity

$args->{quantity} = 4;

lives_ok { $item = Interchange6::Cart::Item->new($args) }
"create Item with good sku, name, price and quantity";

isa_ok( $item, 'Interchange6::Cart::Item' );

is( $item->quantity, 4, "quantity is 4" );

# undef sku

$args->{sku} = undef;

throws_ok { $item = Interchange6::Cart::Item->new($args) } qr/sku.+not defined/,
  "create Item with undef sku";

# empty sku

$args->{sku} = '';

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/sku.+not contain any non-space/, "create Item with empty sku";

# sku > 32 chars

$args->{sku} = 'X' x 33;

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/sku.+length.+32/, "create Item with over-long sku";

# no sku

delete $args->{sku};

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/Missing.+arg.+sku/, "create Item with no sku";

# undef name

$args->{sku} = 'ABC';
$args->{name} = undef;

throws_ok { $item = Interchange6::Cart::Item->new($args) } qr/name.+not defined/,
  "create Item with undef name";

# empty name

$args->{name} = '';

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/name.+not contain any non-space/, "create Item with empty name";

# name > 255 chars

$args->{name} = 'X' x 256;

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/name.+length.+255/, "create Item with over-long name";

# no name

delete $args->{name};

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/Missing.+arg.+name/, "create Item with no name";

# negative quantity

$args->{name} = 'Foobar';
$args->{quantity} = -2;

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/quantity.+not a positive num/, "create Item with negative quantity";

# non-integer quantity

$args->{quantity} = 2.5;

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/quantity.+not an integer/, "create Item with non-integer quantity";

# undef price

$args->{quantity} = 4;
$args->{price} = undef;

throws_ok { $item = Interchange6::Cart::Item->new($args) } qr/price.+not defined/,
  "create Item with undef price";

# empty price

$args->{price} = '';

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/price.+is not a positive num/, "create Item with empty price";

# negative price

$args->{price} = -5;

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/price.+is not a positive num/, "create Item with negative price";

# no price

delete $args->{price};

throws_ok { $item = Interchange6::Cart::Item->new($args) }
qr/Missing.+arg.+price/, "create Item with no price";
