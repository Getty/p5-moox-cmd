package FailTestApp;

use Moo;
use MooX::Cmd execute_from_new => 0;

around _build_command_execute_method_name => sub { "run" };

sub run { @_ }

1;
