package OptionTestApp;

use strict;
use warnings;

use Moo;
use MooX::Cmd execute_from_new => undef;
use MooX::Options;

option in_doubt => (
    is => "ro",
    negativable => 1,
    doc => "in doubt?",
);

sub execute { @_ }

1;
