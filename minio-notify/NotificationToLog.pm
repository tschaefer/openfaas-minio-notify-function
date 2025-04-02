package NotificationToLog;

use Mojo::Base -role;

sub emit {
    my $self = shift;

    my $transport = $self->__setup_transport;
    my $email = $self->__compose_email;

    $self->log->info(sprintf "\n%s", $email->as_string);

    return 1;
}

1;
