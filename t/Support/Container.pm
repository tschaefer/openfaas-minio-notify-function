package Support::Container;

use Mojo::Base -base;

use feature qw(try);
no warnings qw(uninitialized);

use IPC::Run3 qw(run3);
use Mojo::UserAgent;
use List::Util qw(any);

sub run {
    __setup_secrets();

    my $no_cache = sprintf "--no-cache=%s", $ENV{MINIO_NOTIFY_PROVE_NO_CACHE} eq 'true' ? 'true' : 'false';
    fork ? __wait() : __exec('faas-cli', 'local-run', $no_cache);

    return;
}

sub stop {
    __exec('killall', '-9', 'faas-cli');
    __exec('docker', 'container', 'rm', '--force', 'minio-notify');
    __exec('rm', '-rf', 'build');

    __teardown_secrets();

    return;
}

sub __wait {
    my $max_wait = 120;
    my $wait = 0;

    my $ua = Mojo::UserAgent->new->connect_timeout(1);
    while ($wait < $max_wait) {
        try {
            my $result = $ua->get('http://localhost:8080/')->result;

            return if $result->code == 405;
        } catch($e) {
            sleep 1;
            $wait++;
        }
    }

    return;
}

sub __exec {
    my @cmd = @_;

    my $stdout = '';
    my $stderr = '';

    my $verbose = any { $_ eq $ENV{MINIO_NOTIFY_PROVE_VERBOSE} } qw(1 true);
    $verbose ? run3(\@cmd, \undef) : run3(\@cmd, \undef, \$stdout, \$stderr);

    return;
}

sub __setup_secrets {
    return if -e '.secrets/minio-notify';

    __exec('mkdir', '-p', '.secrets');
    __exec('cp', 't/fixtures/secrets.json', '.secrets/minio-notify');
    __exec('touch', '.secrets/.prove');

    return;
}

sub __teardown_secrets {
    return unless -e '.secrets/.prove';

    __exec('rm', '-rf', '.secrets');

    return;
}

1;
