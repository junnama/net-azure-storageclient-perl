package Net::Azure::StorageClient::Blob::Thread;
use base qw/Net::Azure::StorageClient::Blob/;
use strict;
use warnings;
{
  $Net::Azure::StorageClient::Blob::Thread::VERSION = '0.1';
}

use threads;
use Thread::Semaphore;

sub dawnload_use_thread {
    my $blobService = shift;
    my ( $args ) = @_;
    my $thread = $args->{ thread } || 10;
    my $semaphore = new Thread::Semaphore( $thread );
    my $download_items = $args->{ download_items };
    my $params = $args->{ params };
    my $container_name = $args->{ container_name };
    my %th;
    for my $key ( keys %$download_items ) {
        my $item;
        if (! $blobService->{ $container_name } ) {
            $item = $key;
        } else {
            $item = $container_name . '/' . $key,
        }
        $th{ $key } = new threads(\&_download,
                                    $blobService,
                                    $item,
                                    $download_items->{ $key },
                                    $params,
                                    $semaphore );
    }
    my @responses;
    for my $key ( keys %$download_items ) {
        my ( $res ) = $th{ $key }->join();
        push ( @responses, $res );
    }
    return @responses;
}

sub _download {
    my $blobService = shift;
    my ( $from, $to, $params, $semaphore ) = @_;
    $semaphore->down();
    $params->{ force } = 1;
    my $res = $blobService->download( $from, $to, $params );
    $semaphore->up();
    return $res;
}

sub upload_use_thread {
    my $blobService = shift;
    my ( $args ) = @_;
    my $thread = $args->{ thread } || 10;
    my $semaphore = new Thread::Semaphore( $thread );
    my $upload_items = $args->{ upload_items };
    my $params = $args->{ params };
    my %th;
    for my $key ( keys %$upload_items ) {
        $th{ $key } = new threads(\&_upload,
                                    $blobService,
                                    $key,
                                    $upload_items->{ $key },
                                    $params,
                                    $semaphore );
    }
    my @responses;
    for my $key ( keys %$upload_items ) {
        my ( $res ) = $th{ $key }->join();
        push ( @responses, $res );
    }
    return @responses;
}

sub _upload {
    my $blobService = shift;
    my ( $from, $to, $params, $semaphore ) = @_;
    $semaphore->down();
    $params->{ force } = 1;
    my $res = $blobService->upload( $from, $to, $params );
    $semaphore->up();
    return $res;
}

1;