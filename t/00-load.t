#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('MooX::Cmd') || BAIL_OUT("Couldn't load MooX::Cmd");
}

diag( "Testing MooX::Cmd $MooX::Cmd::VERSION, Perl $], $^X" );

done_testing;
