#! perl -T

use strict;
use warnings;

use Test::More;
use Test::Exception;

use aliased 'Interchange6::Cart::Cost';

my ( $cost, %args );

throws_ok { $cost = Cost->new(%args) } qr/missing required arguments/i,
  "fail empty args";

$args{name} = "some name";
throws_ok { $cost = Cost->new(%args) } qr/missing required arguments/i,
  "fail no amount";

$args{amount} = 65;
delete $args{name};
throws_ok { $cost = Cost->new(%args) } qr/missing required arguments/i,
  "fail no name";

$args{name} = undef;
throws_ok { $cost = Cost->new(%args) } qr/not defined/i, "fail undef name";

$args{name} = '';
throws_ok { $cost = Cost->new(%args) } qr/isa.+name.+failed/i,
  "fail empty name";

$args{name} = 'x' x 65;
throws_ok { $cost = Cost->new(%args) } qr/isa.+name.+failed.+length/i,
  "fail name too long";

$args{name}   = "My Name";
$args{amount} = undef;
throws_ok { $cost = Cost->new(%args) } qr/not defined/i, "fail undef amount";

$args{amount} = "string";
throws_ok { $cost = Cost->new(%args) } qr/isa.+amount.+failed.+number/i,
  "fail amount as string";

$args{amount} = 65;
lives_ok { $cost = Cost->new(%args) } "name and amount OK";

$args{id} = undef;
throws_ok { $cost = Cost->new(%args) } qr/isa.+id.+failed.+integer/i,
  "fail undef id";

$args{id} = 1.2;
throws_ok { $cost = Cost->new(%args) } qr/isa.+id.+failed.+integer/i,
  "fail id 1.2";

$args{id} = "string";
throws_ok { $cost = Cost->new(%args) } qr/isa.+id.+failed.+integer/i,
  "fail id string";

$args{id} = 42;
lives_ok { $cost = Cost->new(%args) } "id OK";

cmp_ok( $cost->label,     'eq', "My Name", "label is correct" );
cmp_ok( $cost->relative,  '==', 0,         "relative is 0" );
cmp_ok( $cost->inclusive, '==', 0,         "inclusive is 0" );
cmp_ok( $cost->compound,  '==', 0,         "compound is 0" );
ok( !defined $cost->current_amount, "current_amount is undef" );

$args{label} = undef;
throws_ok { $cost = Cost->new(%args) } qr/not defined/i, "fail undef label";

$args{label} = '';
throws_ok { $cost = Cost->new(%args) } qr/isa.+label.+failed/i,
  "fail empty label";

$args{label} = 'x' x 65;
throws_ok { $cost = Cost->new(%args) } qr/isa.+label.+failed.+length/i,
  "fail label too long";

delete $args{label};

$args{relative} = undef;
throws_ok { $cost = Cost->new(%args) } qr/not defined/i, "fail undef relative";

$args{relative} = "true";
throws_ok { $cost = Cost->new(%args) } qr/isa.+relative.+failed/i,
  "fail relative as string";

$args{relative} = 1;
$args{compound} = undef;
throws_ok { $cost = Cost->new(%args) } qr/not defined/i, "fail undef compound";

$args{compound} = "true";
throws_ok { $cost = Cost->new(%args) } qr/isa.+compound.+failed/i,
  "fail compound as string";

$args{compound}  = 1;
$args{inclusive} = undef;
throws_ok { $cost = Cost->new(%args) } qr/not defined/i, "fail undef inclusive";

$args{inclusive} = "true";
throws_ok { $cost = Cost->new(%args) } qr/isa.+inclusive.+failed/i,
  "fail inclusive as string";

dies_ok { $cost->current_amount(65) } "current_amount is immutable";

lives_ok { $cost->set_current_amount(65) } "set_current_amount 65";

cmp_ok( $cost->current_amount, '==', 65,      "65 coerced to num" );
cmp_ok( $cost->current_amount, 'eq', "65.00", "65.00 coerced to string" );

throws_ok { $cost->set_current_amount() } qr/isa.+current_amount.+number/,
"fail set_current_amount to undef";

done_testing;
