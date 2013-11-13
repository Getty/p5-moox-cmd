package OptionTestApp::Cmd::primary::Cmd::secondary;

use strict;
use warnings;

use Moo;
use MooX::Cmd;
use MooX::Options;

option sure => (
    is => "ro",
    negativable => 1,
    required => 1,
    doc => "sure?",
);

sub execute { @_ }

1;
