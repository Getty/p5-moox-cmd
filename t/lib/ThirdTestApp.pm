package ThirdTestApp;

use Moo;
use MooX::Cmd execute_from_new => undef;

around _build_command_execute_method_name => sub { "run" };

sub mach_mich_perwoll { goto \&MooX::Cmd::Role::_initialize_from_cmd; }

sub run { @_ }

1;
