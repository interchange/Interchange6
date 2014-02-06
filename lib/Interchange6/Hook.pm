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

=head1 SYNOPSIS

  use Interchange6::Hook;
  Interchange6::Hook->register_hooks_name(qw/before_auth after_auth/);

=cut

=method register_hook ($hook_name, [$properties], $code)

    hook 'before', {apps => ['main']}, sub {...};

    hook 'before' => sub {...};

Attaches a hook at some point, with a possible list of properties.

Currently supported properties:

=over 4

=item apps

    an array reference containing apps name

=back

=method register_hooks_name

Add a new hook name, so application developers can insert some code at this point.

    package MyPackage;
    Interchange6::Hook->instance->register_hooks_name(qw/before_auth after_auth/);

=head2 hook_is_registered

Test if a hook with this name has already been registered.

=head2 execute_hook

Execute a hook

=head2 get_hooks_for

Returns the list of coderef registered for a given position

=head1 AUTHOR

Original L<Dancer2> code by Dancer Core Developers
Modifications for Interchange6 by Peter Mottram, peter@sysnix.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alexis Sukrieh.
Interchange modifications are copyright (c) 2014 by Peter Mottram.
 
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

