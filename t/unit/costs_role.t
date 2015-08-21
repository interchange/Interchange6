#! perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

package CostsConsumer {
    use Moo;
    with 'Interchange6::Role::Costs';
    use namespace::clean;

    has subtotal => ( is => 'ro' );
};

my $obj;

lives_ok( sub { $obj = CostsConsumer->new( subtotal => 10 ) },
    "create object with subtotal 10" );
cmp_ok( $obj->subtotal, '==', 10, "subtotal is 10" );
cmp_ok( $obj->total, '==', 10, "total is 10" );

lives_ok( sub { $obj = CostsConsumer->new( subtotal => 20 ) },
    "create object with subtotal 20" );
cmp_ok( $obj->subtotal, '==', 20, "subtotal is 20" );
cmp_ok( $obj->total, '==', 20, "total is 20" );

cmp_ok( $obj->cost_count, '==', 0, "cost_count is 0" );
cmp_ok( scalar $obj->get_costs, '==', 0, "get_costs is empty list" );

done_testing;
