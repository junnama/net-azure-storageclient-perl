#!/usr/bin/perl -w
use strict;
use lib qw( lib );
use Getopt::Long qw/:config posix_default no_ignore_case bundling auto_help/;
use Pod::Usage qw/pod2usage/;
use Net::Azure::StorageClient::Blob;
use Data::Dumper;

my $account_name = '';
my $primary_access_key = '';

GetOptions(\my %options, qw/
    account=s
    accesskey=s
    direction=s
    path=s
    directory=s
    excludes=s
    include_invisible=i
    silence=i
    debug=i
/) or pod2usage( 1 );

$account_name = $options{ account } unless $account_name;
$primary_access_key = $options{ accesskey } unless $primary_access_key;
my $direction = $options{ direction };
my $directory = $options{ directory };
my $path = $options{ path };
my $excludes = $options{ excludes };
my $include_invisible = $options{ 'include_invisible' };
my $silence = $options{ silence };
my $debug = $options{ debug };

if (! $account_name ) {
    print 'Please enter your account name of Windows Azure Blob Storage:';
    $account_name = <STDIN>;
    chomp( $account_name );
}

if (! $primary_access_key ) {
    print 'Please enter your primary access key of Windows Azure Blob Storage:';
    $primary_access_key = <STDIN>;
    chomp( $primary_access_key );
}

if ( (! $account_name ) || (! $primary_access_key ) ) {
    die 
    'Your account and primary access key of Windows Azure Blob Storage are required.';
}

if ( ! $direction || ! $path || ! $directory ) {
    die 
    "Option '--direction', '--path' and '--directory' is required.";
}

if ( ( $direction ne 'upload' ) && ( $direction ne 'download' ) ) {
    die "Option '--direction' is 'upload' or 'download'.";
}

my $blobService = Net::Azure::StorageClient::Blob->new( account_name => $account_name,
                                                        primary_access_key => $primary_access_key,
);

my $params = { direction => $direction };
$params->{ include_invisible } = $include_invisible;
my @exclude_items = split( /,/, $excludes ) if $excludes;
$params->{ excludes } = \@exclude_items  if $excludes;
my $res = $blobService->sync( $path, $directory, $params );
if (! $silence ) {
    if ( ( ref $res ) eq 'ARRAY' ) {
        if ( $debug ) {
            print Dumper $res;
        } else {
            for my $obj ( @$res ) {
                my $uri = $obj->base;
                my $path = $uri->path;
                print  $path . ',' . $obj->code . ',' . $obj->message . "\n";
            }
        }
    } elsif ( ( ref $res ) eq 'HASH' ) {
        if ( $debug ) {
            print Dumper $res;
        } else {
            my $removed_files = $res->{ removed_files };
            my $responses = $res->{ responses };
            for my $obj ( @$responses ) {
                my $uri = $obj->base;
                my $path = $uri->path;
                print  $path . ',' . $obj->code . ',' . $obj->message . "\n";
            }
            for my $file ( @$removed_files ) {
                print  $file . ",,Removed\n";
            }
        }
    } elsif (! $res ) {
        if ( $debug ) {
            print "Blob did not synchronize.\n";
        }
    }
}

1;

__END__

=head1 NAME

Synchronize between the directory of blob storage and the local directory.

=head1 SYNOPSIS

  upload
    perl examples/blobsync.pl --account your_account --accesskey you_primary_access_key --direction upload --path container_name/directory_name --directory /path/to/local/directory [--excludes foo,bar --include_invisible 1 --silence 1 --debug 1]

  download
    perl examples/blobsync.pl --account your_account --accesskey you_primary_access_key --direction download --path container_name/directory_name --directory /path/to/local/directory [--excludes foo,bar --include_invisible 1 --silence 1 --debug 1]

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT

Copyright (C) 2013, Junnama Noda.

=head1 LICENSE

This program is free software;
you can redistribute it and modify it under the same terms as Perl itself.

=cut