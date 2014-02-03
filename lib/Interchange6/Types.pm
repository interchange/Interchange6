# Interchange6::Types - Interchange6 Mooish types

package Interchange6::Types;

use MooX::Types::MooseLike;
use base qw(Exporter);
our @EXPORT_OK = ();

=head1 NAME 

Interchange6::Types - Mooish types for use by Interchange6

=head1 DESCRIPTION

Mooish types for use by Interchange6

=cut

my $defs = [
    {
        name => 'DateTime',
        test => sub { $_[0]->isa('DateTime') },
        message => sub { "$_[0] is not a DateTime object." }
    },
    {
        name => 'HasChars',
        test => sub { $_[0] =~ /\S/ },
        message => sub { "$_[0] does not contain any non-space characters." }
    },
    {
        name => 'VarChar',
        test => sub {
            my ( $value, $param ) = @_;
            length($value) <= $param;
        },
        message =>
          sub { "$_[0] must have length <= $_[1]." }
    },
    {
        name => 'PositiveNum',
        test => sub { $_[0] =~ /^(\d+)(\.\d+)?$/ && $_[0] > 0 },
        message => sub { "$_[0] is not a positive numeric." }
    },
];

MooX::Types::MooseLike::register_types( $defs, __PACKAGE__ );

1;
