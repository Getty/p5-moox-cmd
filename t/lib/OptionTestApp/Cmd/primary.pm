package OptionTestApp::Cmd::primary;

use strict;
use warnings;

use Moo;
use MooX::Cmd;
use MooX::Options;

option serious => (
    is => "ro",
    negativable => 1,
    required => 0,
    doc => "serious?",
);

sub execute { @_ }

1;
