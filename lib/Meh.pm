package Meh;

use strict;
use warnings;
use Moo;
use Import::Into;
use Module::Runtime qw/ require_module /;
use feature 'signatures';
no warnings qw/ experimental::signatures uninitialized /;
use Scalar::Util qw/ reftype /;

sub _dbic_base_class( $class ) {
    my ( $guess ) = $class =~ /(.*::Schema::Result)/;
    eval { require_module $guess };
    return 'DBIx::Class::Core' if $@;
    $guess;
}

{
    sub import ( $module, $type = ':class' ) {
        my ( $caller, $filename ) = caller;

        if ( $type eq ':role' ) {
            'Moo::Role'->import::into( $caller );
        }
        if ( $type eq ':dbic' ) {
            'DBIx::Class::Candy'->import::into( $caller, -base => _dbic_base_class( $caller ) );
            'Moo'->import::into( $caller );
        }
        elsif ( $type eq ':script' ) {
            'Moo'->import::into( $caller );
            'MooX::Options'->import::into( $caller );
        }
        elsif ( $type eq ':nomoo' ) {
            # ¯\_(ツ)_/¯
        }
        else {
            'Moo'->import::into( $caller );
        }

        for my $use ( qw/
                strict warnings utf8 Carp
            / ) {
            $use->import::into( $caller );
        }

        for my $feature ( qw/ signatures state say / ) {
            feature->import::into( $caller, $feature );
        }

        warnings->unimport::out_of( $caller, 'experimental::signatures' );

        return unless my $has = $caller->can( 'has' );

        for my $use ( qw/
                Types::Standard
                Types::Common::String
                Types::Common::Numeric
            / ) {
            $use->import::into( $caller, '-all' );
        }

        for my $is ( qw/ rw ro rwp / ) {
            Moo::_install_tracked $caller => $is => sub( $name, @params ) {
                my $value = @params % 2
                    ? shift @params
                    : undef;
                $has->( $name, is => $is, @params,
                    ( $value
                        ? ( default => reftype $value eq 'CODE'
                            ? $value
                            : sub { $value } )
                        : ()
                    )
                );
            };
        }

        Moo::_install_tracked $caller => 'lazy' => sub( $name, $builder, @params ) {
            $has->( $name, is => 'lazy', builder => $builder, @params );
        };

        Moo::_install_tracked $caller => 'required' => sub( $name, @params ) {
            $has->( $name, is => 'ro', required => 1, @params );
        };

    }
};

1;
