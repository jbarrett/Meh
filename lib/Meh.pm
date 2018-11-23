package Meh;

use strict;
use warnings;
use Moo;
use Import::Into;
use feature 'signatures';
no warnings qw/ experimental::signatures uninitialized /;
use Scalar::Util qw/ reftype /;

{
    sub import ( $module, $type = 'class' ) {
        my ( $caller, $filename ) = caller;

        if ( $type eq 'role' ) {
            'Moo::Role'->import::into( $caller );
        }
        elsif ( $type eq 'script' ) {
            'Moo'->import::into( $caller );
            'MooX::Options'->import::into( $caller );
        }
        else {
            'Moo'->import::into( $caller );
        }

        for my $use ( qw/
                strict warnings utf8 Carp
            / ) {
            $use->import::into( $caller );
        }

        for my $use ( qw/
                Types::Standard
                Types::Common::String
                Types::Common::Numeric
            / ) {
            $use->import::into( $caller, '-all' );
        }

        for my $optionaluse ( qw/
                Quote::Code
            / ) {
            next unless eval qq{ require $optionaluse; };
            $optionaluse->import::into( $caller );
        }

        for my $feature ( qw/ signatures state say / ) {
            feature->import::into( $caller, $feature );
        }

        warnings->unimport::out_of( $caller, 'experimental::signatures' );

        # h/t MooX::ShortHas
        my $has = $caller->can( 'has' ) or die "Moo not loaded in $caller";

        for my $is ( qw/ rw ro rwp / ) {
            Moo::_install_tracked $caller => $is => sub( $name, $value = undef, %params ) {
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

        Moo::_install_tracked $caller => 'lazy' => sub( $name, $builder, %params ) {
            $has->( $name, is => 'lazy', builder => $builder, %params );
        };

    }
};

1;
