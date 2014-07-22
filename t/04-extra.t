#! perl -T
#
# Tests for Interchange6::Cart::Product

use strict;
use warnings;

use Test::More tests => 3;
use Test::Warnings qw/warning :no_end_test/;
use Test::Exception;
use Data::Dumper;
use Interchange6::Cart::Product;
use Interchange6::Cart::Product::Extra;

my ( $args, $product, $name, $ret, $timei, $extra );

# add product

$args = { sku => 'ABC', name => 'Foobar', price => 42 };

lives_ok { $product = Interchange6::Cart::Product->new($args) }
"create Product with good sku, name and price";

isa_ok( $product, 'Interchange6::Cart::Product' );

lives_ok { $product->add_extra(name => 'engraving', value => 'test') }
"create extra";

