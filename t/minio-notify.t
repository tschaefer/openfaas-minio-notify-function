## no critic (Modules::RequireExplicitPackage Modules::RequireEndWithOne)
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin";

use Support::Container;

use Test::More;

use Mojo::File qw(path);
use Mojo::JSON qw(decode_json);
use Mojo::UserAgent;

BEGIN { Support::Container->new->run; }
END   { Support::Container->new->stop; }

my $ua = Mojo::UserAgent->new;
my $url = 'http://localhost:8080';
my $auth = sprintf 'Bearer %s', decode_json(path('.secrets/minio-notify')->slurp)->{auth_token};
my $event = decode_json(path('t/fixtures/event.json')->slurp);
my $res;

subtest 'Method' => sub {
    foreach my $method (qw(get put delete patch options)) {
        $res = $ua->$method($url)->result;
        is($res->code, 405, "$method is not allowed");
    }

    $res = $ua->post($url)->result;
    isnt($res->code, 405, "post is allowed");
};

subtest 'Authorization' => sub {
    $res = $ua->post($url)->result;
    is($res->code, 401, 'when no bearer token is provided, is denied');

    $res = $ua->post($url => { 'Authorization' => 'knock knock ...' })->result;
    is($res->code, 401, 'when bearer token is invalid, is denied');

    $res = $ua->post($url => { 'Authorization' => $auth })->result;
    isnt($res->code, 401, 'when bearer token is valid, is permitted');
};

subtest 'Event' => sub {
    $res = $ua->post($url => { 'Authorization' => $auth })->result;
    is($res->code, 400, 'when no JSON data is provided, is rejected');

    $res = $ua->post($url => { 'Authorization' => $auth, 'X-Notification-Target' => 'Logger' } => json => $event)->result;
    is($res->code, 201, 'when JSON data is provided, is accepted');
};

done_testing();
