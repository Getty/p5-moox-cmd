package MooX::Cmd;
# ABSTRACT: Giving an easy Moo style way to make command organized CLI apps

use strict;
use warnings;
use Package::Stash;

sub import {
	my ( undef, %import_options ) = @_;
	my $caller = caller;
	my @caller_isa;
	{ no strict 'refs'; @caller_isa = @{"${caller}::ISA"} };

	#don't add this to a role
	#ISA of a role is always empty !
	## no critic qw/ProhibitStringyEval/
	@caller_isa or return;

	my $execute_return_method_name = $import_options{execute_return_method_name};

	exists $import_options{execute_from_new} or $import_options{execute_from_new} = 1; # set default until we want other way

	my $stash = Package::Stash->new($caller);
	defined $import_options{execute_return_method_name}
	  and $stash->add_symbol('&'.$import_options{execute_return_method_name}, sub { shift->{$import_options{execute_return_method_name}} });
	defined $import_options{creation_method_name}
	  and $stash->add_symbol('&'.$import_options{creation_method_name}, sub {
		goto &MooX::Cmd::Role::_initialize_from_cmd;;
	});

	my $apply_modifiers = sub {
		$caller->can('_initialize_from_cmd') and return;
		my $with = $caller->can('with');
		$with->('MooX::Cmd::Role');
	};
	$apply_modifiers->();

	my %default_modifiers = (
		base => '_build_command_base',
		execute_method_name => '_build_command_execute_method_name',
		execute_return_method_name => '_build_command_execute_return_method_name',
		creation_chain_methods => '_build_command_creation_chain_methods',
		creation_method_name => '_build_command_creation_method_name',
		execute_from_new => '_build_command_execute_from_new',
	);

	my $around;
	foreach my $opt_key (keys %default_modifiers) {
		exists $import_options{$opt_key} or next;
		$around or $around = $caller->can('around');
		$around->( $default_modifiers{$opt_key} => sub { $import_options{$opt_key} } );
	}

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


