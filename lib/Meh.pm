package Meh;

use Import::Into;

use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Moo::_Utils;

{
    sub import ( $module, $type = 'class' ) {
        my ( $caller, $filename ) = caller;

        for my $use ( qw/
                strict warnings utf8 Carp
            / ) {
            $use->import::into( $caller );
        }

        for my $feature ( qw/ signatures state say / ) {
            feature->import::into( $caller, $feature );
        }

        if ( $type eq 'role' ) {
            require Moo::Role;
            Moo::Role->import::into( $caller );
        }
        elsif ( $type eq 'script' ) {
            require Moo;
            require MooX::Options;
            Moo->import::into( $caller );
            MooX::Options->import::into( $caller );
        }
        else {
            require Moo;
            Moo->import::into( $caller );
        }

        warnings->unimport::out_of( $caller, 'experimental::signatures' );

        return if $type eq 'role';

        # h/t MooX::ShortHas
        my $has = $caller->can( 'has' ) or die "Moo not loaded in $caller";

        _install_coderef $caller . '::ro' => sub( $name, $value, $params = {} ) {
            $has->( $name, is => 'ro', %{ $params },
                ( $value
                    ? ( default => ref $value eq 'CODE'
                        ? $value
                        : sub { $value } )
                    : ()
                )
            );
        };

        _install_coderef $caller . '::lazy' => sub( $name, $builder, $params = {} ) {
            $has->( $name, is => 'lazy', builder => $builder, %{ $params } );
        };

    }
};

1;
