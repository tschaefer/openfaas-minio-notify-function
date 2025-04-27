package Event;

use Mojo::Base -base;

use feature qw(try);

use Mojo::JSON qw(decode_json);

has 'log';
has 'payload';
has 'data';

sub parse {
    my $self = shift;

    my $data = do {
        try {
            decode_json($self->payload);
        } catch($error) {
            ($error) = split / at/, $error;

            $self->log->error("Failed to decode event payload: $error");
            return 0;
        }
    };
    $self->data($data);

    return 1;
}

1;
