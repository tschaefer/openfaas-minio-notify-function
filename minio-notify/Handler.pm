package Handler;

use Mojo::Base -base;
use feature qw(try);
no warnings qw(uninitialized);

use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);

use Authorization;
use Event;
use Notification;

has 'log';
has 'config' => sub {
    my $self = shift;

    return decode_json(path('/var/openfaas/secrets/minio-notify')->slurp);
};

sub run {
    my ($self, $request) = @_;

    return { json => 'Method not allowed', status => 405 } unless $request->method eq 'POST';

    my $auth = Authorization->new
        ->headers($request->headers)
        ->token($self->config->{auth_token})
        ->log($self->log);
    return { json => 'Unauthorized', status => 401 } unless $auth->permitted;

    my $event = Event->new
        ->payload($request->body)
        ->log($self->log);
    return { json => 'Bad Request', status => 400 } unless $event->parse;

    my $roles = $request->headers->header('X-Notification-Target') eq 'Logger' ? ['NotificationToLog'] : [];
    my $notification = Notification->new->with_roles(@$roles)
        ->config($self->config)
        ->event($event->data)
        ->headers($request->headers)
        ->log($self->log);
    return { json => 'Server Error', status => 500 } unless $notification->emit;

    return { json => 'Created', status => 201 };
}

1;
