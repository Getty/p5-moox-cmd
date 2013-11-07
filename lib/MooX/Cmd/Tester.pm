package MooX::Cmd::Tester;

use strict;
use warnings;

require Exporter;
use Test::More import => ['!pass'];
use Package::Stash;

use parent qw(Test::Builder::Module Exporter);

our @EXPORT    = qw(test_cmd test_cmd_ok);
our @EXPORT_OK = qw(test_cmd test_cmd_ok);

our $TEST_IN_PROGRESS;
my $CLASS = __PACKAGE__;

BEGIN
{
    *CORE::GLOBAL::exit = sub {
        return CORE::exit(@_) unless $TEST_IN_PROGRESS;
        MooX::Cmd::Tester::Exited->throw( $_[0] );
    };
}

sub result_class { 'MooX::Cmd::Tester::Result' }

sub test_cmd
{
    my ( $app, $argv ) = @_;

    my $result    = _run_with_capture( $app, $argv );
    my $error     = $result->{error};
    my $exit_code = defined $result->{error} ? ( ( 0 + $! ) || -1 ) : 0;

    $result->{error}
      and eval { $result->{error}->isa('MooX::Cmd::Tester::Exited') }
      and $exit_code = ${ $result->{error} };

    result_class->new(
                       {
                         exit_code => $exit_code,
                         %$result,
                       }
                     );
}

sub test_cmd_ok
{
    my $rv = test_cmd(@_);

    my $test_ident = $rv->app . " => [ " . join( " ", @{$_[1]} ) . " ]";
    ok($rv->cmd->command_commands->{$rv->cmd->command_name}, "found command at $test_ident");

    $rv;
}

sub _run_with_capture
{
    my ( $app, $argv ) = @_;

    require IO::TieCombine;
    my $hub = IO::TieCombine->new;

    my $stdout = tie local *STDOUT, $hub, 'stdout';
    my $stderr = tie local *STDERR, $hub, 'stderr';

    my ( $execute_rv, $cmd );

    my $ok = eval {
        local $TEST_IN_PROGRESS = 1;
        local @ARGV             = @$argv;

        my $tb = $CLASS->builder();

        $cmd = ref $app ? $app : $app->new_with_cmd;
        ref $app and $app = ref $app;
        my $test_ident = "$app => [ " . join( " ", @$argv ) . " ]";
        ok( $cmd->isa($app),    "got a '$app' from new_with_cmd" );
        ok( $cmd->command_name, "proper cmd name from $test_ident" );
        ok( scalar @{ $cmd->command_chain } <= scalar @$argv,
            "\$#argv vs. command chain length testing $test_ident" );
        $cmd->command_execute_from_new
          or $cmd->can( $cmd->command_execute_method_name )->();
        my @execute_return = @{ $cmd->execute_return };
        $execute_rv = \@execute_return;
        1;
    };

    my $error = $ok ? undef : $@;

    return {
             app        => $app,
             cmd        => $cmd,
             stdout     => $hub->slot_contents('stdout'),
             stderr     => $hub->slot_contents('stderr'),
             output     => $hub->combined_contents,
             error      => $error,
             execute_rv => $execute_rv,
           };
}

{

    package MooX::Cmd::Tester::Result;

    sub new
    {
        my ( $class, $arg ) = @_;
        bless $arg => $class;
    }
}

my $res = Package::Stash->new("MooX::Cmd::Tester::Result");
for my $attr (qw(app cmd stdout stderr output error execute_rv exit_code))
{
    $res->add_symbol( '&' . $attr, sub { $_[0]->{$attr} } );
}

{

    package MooX::Cmd::Tester::Exited;

    sub throw
    {
        my ( $class, $code ) = @_;
        defined $code or $code = 0;
        my $self = ( bless \$code => $class );
        die $self;
    }
}

1;
