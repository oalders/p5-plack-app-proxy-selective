use strict;
use warnings;

use Test::Most;

use HTTP::Request;
use HTTP::Request::Common;
use Plack::Test;
use Plack::App::Proxy::Test;
use Test::WWW::Mechanize::PSGI;

use Data::Dumper;

$Plack::Test::Impl = 'Server';

use Plack::App::Proxy::Selective;



subtest 'test with normal string filter' => sub {

    my $selective = Plack::App::Proxy::Selective->new(filter => +{
        'google.com' => +{
            '/script' => '/js',
            'js' => '/js',
         },
    });

    dies_ok {
        $selective->call(+{});
    } 'selective requires env with HTTP_HOST and REQUEST_URI';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/script/test.js' });
    } 'selective maps absolute uri to local dir';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/js/test.js' });
    } 'selective maps relative uri to local dir';

    dies_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/hoge/test.js' });
    } 'Plack::App::Proxy dies without psgi.streaming';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/hoge/test.js', 'psgi.streaming' => 1 });
    } 'Plack::App::Proxy serves other than filtered request';

    done_testing;
};


subtest 'test with regex filter' => sub {

    my $selective = Plack::App::Proxy::Selective->new(filter => +{
        'google.com' => +{
            '/css/.*/' => '/style/',
            '/script/.*' => '/js/ext/',
            '/js/.*js' => '/js/ext/',
         },
    });

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/script/test.js' });
    } 'selective maps ended-with-star uri to local dir';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/script/hoge/test.js' });
    } 'selective maps ended-with-star uri to local dir recursively';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/js/test.js' });
    } 'selective maps specific-suffixed uri to local dir';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/js/test.css', 'psgi.streaming' => 1 });
    } 'Plack::App::Proxy serves other than specific-suffixed requests';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/css/hoge/test.css' });
    } 'selective maps regex-joined uri to local dir';

    lives_ok {
        $selective->call(+{ 'HTTP_HOST' => 'google.com', 'REQUEST_URI' => 'http://google.com/css/test.js', 'psgi.streaming' => 1 });
    } 'Plack::App::Proxy serves other than regex-joined requests';


    done_testing;
};

done_testing;
