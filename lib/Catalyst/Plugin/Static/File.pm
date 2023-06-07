package Catalyst::Plugin::Static::File;

use v5.14;

# ABSTRACT: Serve a specific static file

use Moose::Role;

use File::stat;
use IO::File::WithPath;
use Plack::MIME;

use namespace::autoclean;

our $VERSION = 'v0.1.1';

=head1 SYNOPSIS

In your Catalyst class:

  use Catalyst qw/
      Static::File
    /;

In a controller method:

  $c->serve_static_file( $absolute_path, $type );

=head1 DESCRIPTION

This plugin provides a simple method for your L<Catalyst> app to send a specific static file.

Unlike L<Catalyst::Plugin::Static::File>,

=over

=item *

It only supports serving a single file, not a directory of static files. Use L<Plack::Middleware::Static> if you want to
serve multiple files.

=item *

It assumes that you know what you're doing. If the file does not exist, it will throw an fatal error.

=item *

It uses L<Plack::MIME> to identify the content type, but you can override that.

=item *

It uses L<IO::File::WithPath>, which should play nicely with L<Plack::Middleware::XSendfile> and
L<Plack::Middleware::ETag>.

=back

=method serve_static_file

  $c->serve_static_file( $absolute_path, $type );

This serves the file in C<$absolute_path>, with the C<$type> content type.

If the C<$type> is omitted, it will guess the type using the filename.

It will also set the C<Last-Modified> and C<Content-Length> headers.

It returns a true value on success.

If you want to use conditional requests, use L<Plack::Middleware::ConditionalGET>.

=cut

sub serve_static_file {
    my ( $c, $path, $type ) = @_;

    my $res = $c->res;

    unless ( -e $path ) {
        Catalyst::Exception->throw( "File ${path} was not found" );
    }

    my $fh = IO::File::WithPath->new( $path, "r" );
    if ( defined $fh ) {
        binmode($fh);
        $res->body($fh);

        $type //= Plack::MIME->mime_type($path);

        my $headers = $res->headers;
        $headers->content_type("$type");

        my $stat = stat($path);
        $headers->content_length( $stat->size );
        $headers->last_modified( $stat->mtime );

    }
    else {
        Catalyst::Exception->throw( "Unable to open $path for reading" );
    }

    return 1;
}

=head1 SEE ALSO

L<Catalyst>

L<Catalyst::Plugin::Static::Simple>

=cut

1;
