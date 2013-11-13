#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use Moo;
use MooX::Cmd::Tester;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    eval "use MooX::Options 3.97; use OptionTestApp";
    $@ and plan skip_all => "Need MooX::Options 3.98 $@" and exit(0);
}

my @tests = (
    [ [ qw(--help) ], "OptionTestApp", [ qw(OptionTestApp) ], qr{\QUSAGE: 02-moox-options.t [-h]\E}, qr{\QSUB COMMANDS AVAILABLE: \E(?:oops|primary)} ],
    [ [ qw(primary --help) ], "OptionTestApp", [ qw(OptionTestApp) ], qr{\QUSAGE: 02-moox-options.t primary [-h]\E}, qr{\QSUB COMMANDS AVAILABLE: secondary\E} ],
    [ [ qw(primary secondary --help) ], "OptionTestApp", [ qw(OptionTestApp) ], qr{\QUSAGE: 02-moox-options.t primary secondary [-h]\E} ],
);

for (@tests) {
	my ( $args, $class, $chain, $help, $avail ) = @{$_};
	ref $args or $args = [split(' ', $args)];
	my $rv = test_cmd( $class => $args );

	my $test_ident = "$class => " . join(" ", "[", @$args, "]");
	like( $rv->stdout, $help, "test '$test_ident' help message ok" );
	$avail and like( $rv->stdout, $avail, "test '$test_ident' avail commands ok" );
	$avail or unlike( $rv->stdout, qr{\QAvailable commands\E}, "test '$test_ident' avail commands ok" );
}

done_testing;
