package Interchange6::Role::Errors;
use Moo::Role;
use MooX::HandlesVia;
use Interchange6::Types;

# The errors registry
<<<<<<< HEAD
has _errors => (
=======
has errors => (
>>>>>>> add new Errors role
    is          => 'rw',
    default     => sub { [] },
    handles_via => 'Array',
    handles => {
<<<<<<< HEAD
        errors       => 'all',
=======
        all          => 'all',
>>>>>>> add new Errors role
        has_error    => 'count',
        has_errors   => 'count',
        clear_error  => 'clear',
        clear_errors => 'clear',
        set_error    => 'push',
    },
);

sub get_error {
    my $self = shift;
<<<<<<< HEAD
    return join(':', $self->errors);
};
sub error {
    my $self = shift;
    return join(':', $self->errors);
=======
    return join(':', $self->all);
};
sub get_errors {
    my $self = shift;
    return join(':', $self->all);
};
sub error {
    my $self = shift;
    return join(':', $self->all);
>>>>>>> add new Errors role
};

1;
