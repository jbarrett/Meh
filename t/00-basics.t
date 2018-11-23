use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package FooTest;

    use Meh;

    ro 'foo';

    required 'bar';

    rw baz => 20,
       coerce => sub( $val ) { $val + 2 };

    rwp 'qux';

    lazy quux => sub( $self ) { $self->baz * 2 };

    ro quuz => isa => NegativeInt;

    rw corge => isa => FileHandle;

    sub change_qux( $self, $new ) {
        $self->_set_qux( $new );
    }

    1;
}

throws_ok sub { FooTest->new },
          qr/Missing required arguments: bar/,
          'Required attribute';

throws_ok sub { FooTest->new( bar => 1, quuz => 'abc' ) },
          qr/Must be a negative integer/,
          'Type constraint - NegativeInt - Failure';
lives_ok  sub { FooTest->new( bar => 1, quuz => -1 ) },
          'Type constraint - NegativeInt - Success';

open my $fh, '<', __FILE__;
throws_ok sub { FooTest->new( bar => 1, corge => 'abc' ) },
          qr/did not pass type constraint "FileHandle"/,
          'Type constraint - FileHandle - Failure';
lives_ok  sub { FooTest->new( bar => 1, corge => $fh ) },
          'Type constraint - FileHandle - Success';

my $foo = FooTest->new( bar => 1 );

throws_ok sub { $foo->qux( 'asd' ) },
          qr/Usage: FooTest::qux\(self\)/,
          'rwp set properly - set accessor';
lives_ok  sub { $foo->change_qux('asd') },
          'rwp set properly - internal set accessor';
is( $foo->qux, 'asd', 'rwp set properly - value' );

is( $foo->baz, 22, 'coercion set properly' );
is( $foo->quux, 44, 'lazy set correctly' );
lives_ok sub { $foo->baz(30) }, 'rw set properly';
is( $foo->baz, 32, 'coercion set properly after rw' );
is( $foo->quux, 44, 'lazy still set correctly' );

done_testing;

