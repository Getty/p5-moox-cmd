package MooX::Cmd;
# ABSTRACT: Giving an easy Moo style way to make command organized CLI apps

use strict;
use warnings;
use Module::Pluggable::Object;
use Package::Stash;

my %DEFAULT_OPTIONS = (
	'creation_chain_methods' => ['new_with_options','new'],
	'creation_method_name' => 'new_with_cmd',
	'execute_return_method_name' => 'execute_return',
	'execute_method_name' => 'execute',
	'execute_from_new' => undef,
	'base' => undef,
);

sub _mkcommand {
	my ( $package, $base ) = @_;
	$package =~ s/^${base}:://g;
	lc($package);
}

sub import {
	my ( undef, %import_params ) = @_;
	my ( %import_options ) = ( %DEFAULT_OPTIONS, %import_params );
	my $caller = caller;
	my @caller_isa;
	{ no strict 'refs'; @caller_isa = @{"${caller}::ISA"} };

	#don't add this to a role
	#ISA of a role is always empty !
	## no critic qw/ProhibitStringyEval/
	@caller_isa or return;

	my $execute_return_method_name = $import_options{execute_return_method_name};
	my $execute_method_name = $import_options{execute_method_name};
	my $base = $import_options{base} ? $import_options{base} : ($caller.'::Cmd');

	defined $import_options{execute_from_new} or $import_options{execute_from_new} = 1; # set default until we want other way

	# i have no clue why 'only' and 'except' seems to not fulfill what i need or are bugged in M::P - Getty
	my @cmd_plugins = grep {
		my $class = $_;
		$class =~ s/${base}:://;
		$class !~ /:/;
	} Module::Pluggable::Object->new(
		search_path => $base,
		require => 0,
	)->plugins;

	my $stash = Package::Stash->new($caller);
	my %cmds;

	for my $cmd_plugin (@cmd_plugins) {
		$cmds{_mkcommand($cmd_plugin,$base)} = $cmd_plugin;
	}

	$stash->add_symbol('&'.$execute_return_method_name, sub { shift->{$execute_return_method_name} });
	$stash->add_symbol('&'.$import_options{creation_method_name}, sub {
		return shift->_initialize_from_cmd(@_, command_commands => \%cmds, __cmd_create_options => \%import_options);
	});

	my $apply_modifiers = sub {
		$caller->can('_initialize_from_cmd') and return;
		my $with = $caller->can('with');
		$with->('MooX::Cmd::Role');
	};
	$apply_modifiers->();

	return;
}

1;

=encoding utf8

=head1 SYNOPSIS

  package MyApp;

  use Moo;
  use MooX::Cmd;

  sub execute {
    my ( $self, $args_ref, $chain_ref ) = @_;
    my @extra_argv = @{$args_ref};
    my @chain = @{$chain_ref} # in this case only ( $myapp )
                              # where $myapp == $self
  }

  1;
 
  package MyApp::Cmd::Command;
  # for "myapp command"

  use Moo;
  use MooX::Cmd;

  # gets executed on "myapp command" but not on "myapp command command"
  # there MyApp::Cmd::Command still gets instantiated and for the chain
  sub execute {
    my ( $self, $args_ref, $chain_ref ) = @_;
    my @chain = @{$chain_ref} # in this case ( $myapp, $myapp_cmd_command )
                              # where $myapp_cmd_command == $self
  }

  1;

  package MyApp::Cmd::Command::Cmd::Command;
  # for "myapp command command"

  use Moo;
  use MooX::Cmd;

  # gets executed on "myapp command command" and will not get instantiated
  # on "myapp command" cause it doesnt appear in the chain there
  sub execute {
    my ( $self, $args_ref, $chain_ref ) = @_;
    my @chain = @{$chain_ref} # in this case ( $myapp, $myapp_cmd_command,
                              # $myapp_cmd_command_cmd_command )
                              # where $myapp_cmd_command_cmd_command == $self
  }

  package MyZapp;

  use Moo;
  use MooX::Cmd execute_from_new => 0;

  sub execute {
    my ( $self ) = @_;
    my @extra_argv = @{$self->command_args};
    my @chain = @{$self->command_chain} # in this case only ( $myzapp )
                              # where $myzapp == $self
  }

  1;
 
  package MyZapp::Cmd::Command;
  # for "myapp command"

  use Moo;
  use MooX::Cmd execute_from_new => 0;

  # gets executed on "myapp command" but not on "myapp command command"
  # there MyApp::Cmd::Command still gets instantiated and for the chain
  sub execute {
    my ( $self ) = @_;
    my @extra_argv = @{$self->command_args};
    my @chain = @{$self->command_chain} # in this case ( $myzapp, $myzapp_cmd_command )
                              # where $myzapp_cmd_command == $self
  }

  1;
  package main;

  use MyApp;

  MyZapp->new_with_cmd->execute();
  MyApp->new_with_cmd;

  1;

=head1 DESCRIPTION

Works together with L<MooX::Options> for every command on its own, so options are
parsed for the specific context and used for the instantiation:

  myapp --argformyapp command --argformyappcmdcommand ...

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-moox-cmd
  Pull request and additional contributors are welcome
 
Issue Tracker

  http://github.com/Getty/p5-moox-cmd/issues


