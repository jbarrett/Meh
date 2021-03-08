use strict;
use warnings;

use Test::More;
use Test::Exception;

{
    package FooTest;

    use Meh;

    singleton http1 => 'HTTP::Tiny', agent => 'bar';
    instance  http2 => 'HTTP::Tiny', agent => 'foo';

    1;
}

{
    package BarTest;

    use Meh;

    singleton http => 'HTTP::Tiny';
}

my $foo1 = FooTest->new;
my $foo2 = FooTest->new;
my $bar  = BarTest->new;

isa_ok( $_, 'HTTP::Tiny' ) for (
    $foo1->http1,
    $foo1->http2,
    $foo2->http1,
    $foo2->http2,
    $bar->http
);

is( $foo1->http1, $foo2->http1, 'singleton is same instance' );
is( $bar->http,   $foo2->http1, 'singleton is same instance' );

isnt( $foo1->http1, $foo1->http2, 'instance is new instance' );

is( $foo1->http1->agent, $bar->http->agent, 'instance params persist');

done_testing;

