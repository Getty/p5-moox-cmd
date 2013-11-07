package SecondTestApp::Cmd::ifc;

use Moo;

BEGIN { with "MooX::Cmd::Role"; }

around _build_command_execute_method_name => sub { "run" };

around _build_command_execute_from_new => sub { 1 };

sub run { @_ }

eval "use MooX::Cmd;";

1;
