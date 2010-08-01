package Plack::App::Proxy::Selective;

use strict;
use warnings;

use parent qw/Plack::Component/;

use Plack::Util::Accessor qw/filter/;
use Plack::App::Proxy;
use Plack::App::Directory;

use Data::Dumper;

use Path::Class;

our $VERSION = '0.01';

my $base_dir = file(__FILE__)->dir;


sub match_uri {
    my ($env, $source_dir) = @_;

    if ( $env->{'REQUEST_URI'} =~ /$env->{'HTTP_HOST'}\/?$source_dir(\/?\w+\.\w+)?/ ) {
        my $result;

        if ( $1 ) {
            $result = $1;
        }
        else {
            $& =~ /(\w+\.\w+$)/;
            $result = $1;
        }
        warn $result;
        return $result;
    }
}

sub server_local {
    my $target_dir = shift;
    return Plack::App::Directory->new(root => $base_dir->subdir($target_dir));
}

sub call {
    my ($self, $env) = @_;

    while ( my ($key, $value) = each %$env ) {
        warn "$key -> $value\n";
    }
    warn $env->{'REQUEST_URI'};
    warn 'call';

    my %filter = %{$self->filter};

    while( my ($host, $mapping) = each %filter ) {
        warn 'loop';
        if ( $env->{'HTTP_HOST'} =~ /$host/ ) {
            warn 'first match';
            my %mapping = %{$mapping};
            while ( my ($source_dir, $target_dir) = each %mapping ) {
                if ( my $path = match_uri($env, $source_dir) ) {
                    warn 'second match';
                    my $dir = server_local($target_dir)->to_app;
                    $env->{PATH_INFO} = $path;
                    return $dir->($env);
                }
            }
        }
    }

    warn 'proxy';

    my $proxy = Plack::App::Proxy->new->to_app;
    $env->{'plack.proxy.url'} = $env->{'REQUEST_URI'};
    return $proxy->($env);
}

1;
__END__

=head1 NAME

Plack::App::Proxy::Selective -

=head1 SYNOPSIS

  use Plack::App::Proxy::Selective;

=head1 DESCRIPTION

Plack::App::Proxy::Selective is

=head1 AUTHOR

zentooo E<lt>ankerasoy@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
