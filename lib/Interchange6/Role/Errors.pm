package Interchange6::Role::Errors;
use Moo::Role;
use MooX::HandlesVia;
use Interchange6::Types;

# The errors registry
has _errors => (
    is          => 'rw',
    default     => sub { [] },
    handles_via => 'Array',
    handles => {
        errors       => 'all',
        has_error    => 'count',
        has_errors   => 'count',
        clear_error  => 'clear',
        clear_errors => 'clear',
        set_error    => 'push',
    },
);

sub get_error {
    my $self = shift;
    return join(':', $self->errors);
};
sub error {
    my $self = shift;
    return join(':', $self->errors);
};

1;

=head1 NAME

Interchange6::Role::Errors - errors role

=head1 METHODS

=head2 error

Alias for get_error.

=head2 errors       => 'all',

Returns errors as array.

=head2 has_error    => 'count',

Alias for has_errors.

=head2 has_errors   => 'count',

Actually returns the error count so 0 for no errors and 1+ if there are errors.

=head2 clear_error  => 'clear',

Alias for clear_errors.

=head2 clear_errors => 'clear',

Clears all errors.

=head2 set_error    => 'push',

Adds add error.

=head2 get_error

Returns all errors as a scalar joined with ':'.
