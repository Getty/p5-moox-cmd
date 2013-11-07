package SecondTestApp::Cmd::cwo;

use Moo;

use MooX::Cmd execute_return_method_name => 'run_result', creation_method_name => "mach_mich_neu";

around _build_command_execute_method_name => sub { "run" };

sub run { @_ }

1;
