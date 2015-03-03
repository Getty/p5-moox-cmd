package ConfigApp::Cmd::Check;

use strict;
use warnings;

BEGIN {
    my $moodel = $ENV{WHICH_MOODEL} || "Moo";
    eval "use $moodel;"; $@ and die $@;
    $moodel->import;
}
use MooX::Cmd;

has unintialized_attribute => (is => "lazy");

sub _build_unintialized_attribute { time }

sub execute { @_ }

1;
