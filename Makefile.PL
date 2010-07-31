use inc::Module::Install;
name 'Plack-App-Proxy-Selective';
all_from 'lib/Plack/App/Proxy/Selective.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
