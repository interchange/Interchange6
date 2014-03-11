package Interchange6::Role::Hookable;
use Moo::Role;
use Interchange6::Types;
use Carp 'croak';

requires 'supported_hooks';

# The hooks registry
has hooks => (
    is      => 'rw',
    isa     => HashRef,
    builder => '_build_hooks',
    lazy    => 1,
);

# mst++ for the hint
sub _build_hooks {
    my ($self) = @_;
    my %hooks = map +( $_ => [] ), $self->supported_hooks;
    return \%hooks;
}

# This binds a coderef to an installed hook if not already
# existing
sub add_hook {
    my ( $self, $hook ) = @_;
    my $name = $hook->name;
    my $code = $hook->code;

    croak "Unsupported hook '$name'"
      unless $self->has_hook($name);

    push @{ $self->hooks->{$name} }, $code;
}

# allows the caller to replace the current list of hooks at the given position
# this is useful if the object where this role is composed wants to compile the
# hooks.
sub replace_hook {
    my ( $self, $position, $hooks ) = @_;

    croak "Hook '$position' must be installed first"
      unless $self->has_hook($position);

    $self->hooks->{$position} = $hooks;
}

# Boolean flag to tells if the hook is registered or not
sub has_hook {

    #print Dumper(@_);
    my ( $self, $name ) = @_;
    return exists $self->hooks->{$name};
}

# Execute the hook at the given position
sub execute_hook {
    my ( $self, $name, @args ) = @_;

    croak "execute_hook needs a hook name"
      if !defined $name || !length($name);

    croak "Hook '$name' does not exist"
      if !$self->has_hook($name);

    my $res;
    $res = $_->(@args) for @{ $self->hooks->{$name} };
    return $res;
}

sub supported_hooks {
    qw/
      before_cart_add_validate
      before_cart_add
      after_cart_add
      before_cart_remove_validate
      before_cart_remove
      after_cart_remove
      before_cart_update
      after_cart_update
      before_cart_clear
      after_cart_clear
      before_cart_set_users_id
      after_cart_set_users_id
      before_cart_set_sessions_id
      after_cart_set_sessions_id
      before_cart_rename
      after_cart_rename
      /;
}

1;

=head1 NAME

Interchange6::Role::Hookable - hooks for Interchange6

=head1 METHODS

=head2 add_hook

Binds a coderef to an installed hook.

=head2 execute_hook

Execute the hook at the given position.

=head2 has_hook

Boolean flag to tells if the hook is registered or not.

=head2 replace_hook

Allows the caller to replace the current list of hooks at the given position
this is useful if the object where this role is composed wants to compile the
hooks.

=head2 supported_hooks

Adds the base hook names used by Interchange6.

=head1 AUTHOR

Original L<Dancer2> code by Dancer Core Developers
Modifications for Interchange6 by Peter Mottram, peter@sysnix.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2014 by Alexis Sukrieh.
Interchange modifications are copyright (c) 2014 by Peter Mottram.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

