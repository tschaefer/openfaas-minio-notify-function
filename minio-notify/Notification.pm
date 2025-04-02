package Notification;

use feature qw(try);

use Mojo::Base -base;

use Authen::SASL;
use MIME::Base64 qw(encode_base64);

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::Simple ();

has 'config';
has 'event';
has 'headers';
has 'log';

sub emit {
    my $self = shift;

    my $transport = $self->__setup_transport;
    my $email = $self->__compose_email;

    try {
        sendmail($email, { transport => $transport });
    } catch($error) {
        ($error) = split /\n/, $error;

        $self->log->error("Failed to send email: $error");

        return 0;
    }

    return 1;
}

sub __compose_email {
    my $self = shift;

    my $content = $self->__create_content;
    return Email::Simple->create(
      header => [
        To      => $self->config->{to},
        From    => $self->config->{from},
        Subject => $content->{subject},
      ],
      body => $content->{body}
    );
}

sub __setup_transport {
    my $self = shift;

    return Email::Sender::Transport::SMTP->new({
        host => $self->config->{host},
        ssl  => $self->config->{ssl},
        port => $self->config->{port},
        sasl_username => $self->config->{username},
        sasl_password => $self->config->{password},
    });
}

sub __create_content {
    my $self = shift;

    my $records = $self->event->{Records}->[0];

    my $key          = $self->event->{Key};
    my $event_type   = $records->{eventName};
    my $timestamp    = $records->{eventTime};
    my $bucket_name  = $records->{s3}->{bucket}->{name};
    my $file_name    = $records->{s3}->{object}->{key};
    my $file_size    = $records->{s3}->{object}->{size};
    my $content_type = $records->{s3}->{object}->{contentType};
    my $minio_url    = $records->{responseElements}->{"x-minio-origin-endpoint"};

    my ($action) = $event_type =~ /s3:Object(\w+):\w+/;
    $action = lc $action;

    my $subject = "Object '$key' successfully $action";
    (my $body = <<"    END_BODY") =~ s/^ {8}//mg;
        * Event Type: $event_type
        * Timestamp: $timestamp
        * Bucket Name: $bucket_name
        * File Name: $file_name
        * File Size: $file_size bytes
        * Content Type: $content_type
        * Endpoint: $minio_url
    END_BODY

    my $content = {
        subject => $subject,
        body    => $body,
    };

    return $content;
}

1;
