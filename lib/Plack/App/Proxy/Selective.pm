package Plack::App::Proxy::Selective;

use strict;
use warnings;

use parent qw/Plack::Component/;

use Plack::Util::Accessor qw/filter base_dir/;
use Plack::App::Proxy;
use Plack::App::Directory;
use Path::Class;

our $VERSION = '0.02';

my $filename = qr/\/?(?:\w+?\.)+\w+$/;

sub match_uri {
    my ($env, $source_dir) = @_;

    if ( $env->{'REQUEST_URI'} =~ /$env->{'HTTP_HOST'}\/?$source_dir($filename)?/ ) {
        return $1 || ($& =~ /($filename)/ && $1) || undef;
    }
}

sub server_local {
    my ($base_dir, $target_dir) = @_;
    return Plack::App::Directory->new(root => $base_dir->subdir($target_dir));
}

sub call {
    my ($self, $env) = @_;

    my %filter = %{$self->filter};

    while( my ($host, $mapping) = each %filter ) {

        if ( $env->{'HTTP_HOST'} =~ /$host/ ) {
            for my $source_dir ( keys %{$mapping} ) {
                if ( my $path = match_uri($env, $source_dir) ) {
                    my $dir = server_local($self->base_dir, $mapping->{$source_dir})->to_app;
                    $env->{PATH_INFO} = $path;
                    return $dir->($env);
                }
            }
        }
    }

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
