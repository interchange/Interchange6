package Interchange6::Hook;
use Moo;
use Interchange6::Types;
use Carp 'croak';

has name => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has code => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
    coerce   => sub {
        my ($hook) = @_;
        sub {
            my $res;
            eval { $res = $hook->(@_) };
            croak "Hook error: $@" if $@;
            return $res;
        };
    },
);

1;

=head1 NAME

Interchange6::Hook - Hook class for Interchange6 Shop Machine

=head1 ATTRIBUTES

=head2 name

Name of hook - a string;

=head2 code

Coderef attached to hook.

=head1 AUTHOR

Original L<Dancer2> code by Dancer Core Developers
Modifications for Interchange6 by Peter Mottram, peter@sysnix.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2014 by Alexis Sukrieh.
Interchange modifications are copyright (c) 2014 by Peter Mottram.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

