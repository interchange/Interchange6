#! perl -T
#
# Tests for Interchange6::Cart::Product

use strict;
use warnings;

use Test::More tests => 5;
use Test::Warnings qw/warning :no_end_test/;
use Test::Exception;
use Data::Dumper;
use Interchange6::Cart::Product;
use Interchange6::Cart::Product::Extra;

my ( $args, $product, $name, $cart_product_extra_id, $extra );

# add product

$args = { sku => 'ABC', name => 'Foobar', price => 42 };

lives_ok { $product = Interchange6::Cart::Product->new( $args) }
"create Product with good sku, name and price";

isa_ok( $product, 'Interchange6::Cart::Product' );

$cart_product_extra_id = '10';

lives_ok { $product->add_extra($cart_product_extra_id, {name => 'foo', value => 'bar'}) }
"create extra";

is( $product->{extra}{$cart_product_extra_id}{name}, 'foo', "name is foo" );
is( $product->{extra}{$cart_product_extra_id}{value}, 'bar', "value is bar" );

