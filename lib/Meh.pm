package Meh;

use strict;
use warnings;
use Moo;
use Import::Into;
use Module::Runtime qw/ require_module /;
use feature qw/ signatures /;
no warnings qw/ experimental::signatures uninitialized /;
use Scalar::Util qw/ reftype /;
use Carp qw/ croak /;

my $_instance_cache;

sub _dbic_base_class( $class ) {
    my ( $guess ) = $class =~ /(.*::Schema::Result)/;
    eval { require_module $guess };
    return 'DBIx::Class::Core' if $@;
    $guess;
}

sub _resolve_imports( @imports ) {
    my $mode_tags = +{
        map {; ":$_" => 1 }
        qw/ role dbic script nomoo moo /
    };

    my @local_imports = my @remote_imports = @imports;

    for my $idx ( 0..$#imports ) {
        if ( $imports[$idx] eq '--' ) {
            @local_imports = @imports[0..$idx-1];
            @remote_imports = @imports[$idx+1..$#imports];
            last;
        }
    }

    my @modes = grep { $mode_tags->{$_} } @local_imports;
    croak sprintf(
        "Unable to resolve modes %s",
        join( ', ', @modes )
    ) if @modes > 1;

    my $cfg = +{ map { s/^://r => 1 } grep { /^:/ } @local_imports };

    return ( $cfg, @remote_imports );
}

{
    sub import ( $module, @imports ) {
        my ( $caller, $filename ) = caller;

        my ( $cfg, @options ) = _resolve_imports( @imports );

        if ( $cfg->{role} ) {
            'Moo::Role'->import::into( $caller );
        }
        elsif ( $cfg->{dbic} ) {
            'DBIx::Class::Candy'->import::into( $caller, -base => _dbic_base_class( $caller ), @options );
            'Moo'->import::into( $caller );
        }
        elsif ( $cfg->{script} ) {
            'Moo'->import::into( $caller );
            'MooX::Options'->import::into( $caller, @options );
        }
        elsif ( $cfg->{nomoo} ) {
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

        for my $feature ( qw/ signatures state say isa / ) {
            feature->import::into( $caller, $feature );
        }

        'open'->import::into( $caller, qw/ :encoding(UTF-8) :std / )
            unless $cfg->{noperlio};

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
                        ? ( builder => reftype $value eq 'CODE'
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

        my $instance = sub( $class, @params ) {
            "$class"->import::into( $caller ); return "$class"->new( @params )
        };

        Moo::_install_tracked $caller => 'singleton' => sub( $name, $class, @params ) {
            $has->( $name, is => 'ro', builder => sub {
                return $_instance_cache->{ $class } if $_instance_cache->{ $class };
                $_instance_cache->{ $class } = $instance->( $class, @params )
            } );
        };

        Moo::_install_tracked $caller => 'instance' => sub( $name, $class, @params ) {
            $has->( $name, is => 'ro', builder => sub {
                $instance->( $class, @params )
            } );
        };

        Moo::_install_tracked $caller => 'required' => sub( $name, @params ) {
            $has->( $name, is => 'ro', required => 1, @params );
        };

    }
};

1;
