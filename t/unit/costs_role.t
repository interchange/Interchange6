#! perl

use warnings;
use strict;

use Test::More;
use Test::Exception;
use aliased 'Interchange6::Cart::Cost';

package CostsConsumer {
    use Moo;
    with 'Interchange6::Role::Costs';
    use namespace::clean;

    has subtotal => ( is => 'ro' );
};

my ( $obj, $cost );

lives_ok { $obj = CostsConsumer->new( subtotal => 10 ) }
"create object with subtotal 10";

cmp_ok( $obj->subtotal, '==', 10, "subtotal is 10" );
cmp_ok( $obj->total,    '==', 10, "total is 10" );

lives_ok { $obj = CostsConsumer->new( subtotal => 20 ) }
"create object with subtotal 20";

cmp_ok( $obj->subtotal, '==', 20, "subtotal is 20" );
cmp_ok( $obj->total,    '==', 20, "total is 20" );

cmp_ok( $obj->cost_count,       '==', 0, "cost_count is 0" );
cmp_ok( scalar $obj->get_costs, '==', 0, "get_costs is empty list" );

throws_ok { $obj->apply_cost } qr/argument to apply_cost undefined/,
  "fail apply_cost with no args";

throws_ok { $obj->apply_cost($obj) } qr/Supplied cost not an.+Cost/,
  "fail apply_cost bad obj as arg";

lives_ok { $cost = Cost->new( name => "My Cost", amount => 12 ) }
"create a Cost object with name 'My Cost' and amount 12";

lives_ok { $obj->apply_cost($cost) } "apply_cost Cost object";

cmp_ok( $obj->subtotal, '==', 20, "subtotal is 20" );
cmp_ok( $obj->total,    '==', 32, "total is 32" );

done_testing;
