#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use FirstTestApp;

my @tests = (
	[ 'test', [ "FirstTestApp::Cmd::Test", [], [ "FirstTestApp" ] ] ],
	[ 'test test', [ "FirstTestApp::Cmd::Test::Cmd::Test", [], [ "FirstTestApp","FirstTestApp::Cmd::Test" ] ] ],
	[ 'test this', [ "FirstTestApp::Cmd::Test", [ "this" ], [ "FirstTestApp" ] ] ],
	[ 'this test test this', [ "FirstTestApp::Cmd::Test::Cmd::Test", [ "this" ], [ "FirstTestApp","FirstTestApp::Cmd::Test" ] ] ],
	[ 'test this test', [ "FirstTestApp::Cmd::Test::Cmd::Test", [], [ "FirstTestApp","FirstTestApp::Cmd::Test" ] ] ],
);

for (@tests) {
	my ( $args, $result ) = @{$_};
	@ARGV = split(' ', $args);
	my $app = FirstTestApp->new_with_cmd;
	isa_ok($app,'FirstTestApp');
	my @execute_return = @{$app->execute_return};
	my @moox_cmd_chain = map { ref $_ } @{$execute_return[2]};
	my $execute_result = [ref $execute_return[0],$execute_return[1],\@moox_cmd_chain];
	is_deeply($execute_result,$result,'Checking result of "'.$args.'"');
}

done_testing;
