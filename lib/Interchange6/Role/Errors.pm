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
