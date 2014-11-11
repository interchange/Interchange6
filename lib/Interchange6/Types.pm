# Interchange6::Types - Interchange6 Mooish types

package Interchange6::Types;

use MooX::Types::MooseLike;
use MooX::Types::MooseLike::Base qw/:all/;
use Scalar::Util 'blessed';

use Exporter 'import';
our @EXPORT    = ();
our @EXPORT_OK = ();

my $defs = [
    {
        name => 'DateAndTime',
        test => sub {
            return $_[0] && blessed( $_[0] ) && ref( $_[0] ) eq 'DateTime';
        },
        message => sub { "The value `$_[0]' is not a DateTime object." },
    },
    {
        name    => 'NotEmpty',
        test    => sub { $_[0] =~ /\S/ },
        message => sub { "Must contain some non-space characters." }
    },
    {
        name => 'VarChar',
        test => sub {
            my ( $value, $param ) = @_;
            length($value) <= $param;
        },
        message => sub { "$_[0] must have length <= $_[1]." }
    },
    {
        name => 'PositiveNum',
        test => sub { defined($_[0]) && $_[0] =~ /^(\d+)(\.\d+)?$/ && $_[0] > 0 },
        message => sub { "is not a positive numeric." }
    },
    {
        name => 'Zero',
        test =>
          sub { defined( $_[0] ) && $_[0] =~ /^(\d+)(\.\d+)?$/ && $_[0] == 0 },
        message => sub { "is not zero." }
    },
];

for my $type (
    qw/
    /
  )
{
    ( my $name = $type ) =~ s/Interchange6:://;
    push @$definitions, {
        name => $name,
        test => sub {
            return
                 $_[0]
              && blessed( $_[0] )
              && ref( $_[0] ) eq $type;
        },
        message =>
          sub { "The value `$_[0]' does not pass the constraint check." },
        inflate => 0,
    };
}

MooX::Types::MooseLike::register_types( $defs, __PACKAGE__ );

# Export everything by default.
@EXPORT = ( @MooX::Types::MooseLike::Base::EXPORT_OK, @EXPORT_OK );

1;

=head1 NAME 

Interchange6::Types - Mooish types for use by Interchange6

=head1 DESCRIPTION

Mooish types for use by Interchange6

=cut

