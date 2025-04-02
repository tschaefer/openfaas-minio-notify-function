package Authorization;

use Mojo::Base -base;

has 'headers';
has 'log';
has 'token';

sub permitted {
    my $self = shift;

    return 0 unless $self->headers;

    my $auth_header = $self->headers->header('Authorization');
    return 0 unless $auth_header;

    my ($type, $token) = split /\s+/, $auth_header;
    return 0 unless $type && $token;

    return 0 if $token ne $self->token;

    return 1;
}

1;
