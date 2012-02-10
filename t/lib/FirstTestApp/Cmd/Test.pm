package FirstTestApp::Cmd::Test;

use Moo;
use MooX::Cmd;

command 'test2';

sub execute { @_ }

1;