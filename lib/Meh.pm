package Meh;

use Import::Into;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/ experimental::signatures uninitialized /;
use Moo::_Utils;
use Scalar::Util qw/ reftype /;

{
    sub import ( $module, $type = 'class' ) {
        my ( $caller, $filename ) = caller;

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

        for my $use ( qw/
                strict warnings utf8 Carp
                Types::Standard
                Types::Common::String
                Types::Common::Numeric
            / ) {
            $use->import::into( $caller );
        }

        for my $feature ( qw/ signatures state say / ) {
            feature->import::into( $caller, $feature );
        }

        warnings->unimport::out_of( $caller, 'experimental::signatures' );

        return if $type eq 'role';

        # h/t MooX::ShortHas
        my $has = $caller->can( 'has' ) or die "Moo not loaded in $caller";

        for my $is ( qw/ rw ro rwp / ) {
            _install_coderef $caller . "::$is" => sub( $name, $value, %params ) {
                $has->( $name, is => $is, %params,
                    ( $value && !$params{required}
                        ? ( default => reftype $value eq 'CODE'
                            ? $value
                            : sub { $value } )
                        : ()
                    )
                );
            };
        }

        _install_coderef $caller . '::lazy' => sub( $name, $builder, %params ) {
            $has->( $name, is => 'lazy', builder => $builder, %params );
        };

    }
};

1;
