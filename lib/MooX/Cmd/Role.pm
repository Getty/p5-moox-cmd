package MooX::Cmd::Role;
# ABSTRACT: MooX cli app commands do this

use strict;
use warnings;

use Moo::Role;

use Carp;
use Module::Runtime qw/ use_module /;
use Regexp::Common;
use Data::Record;
use Module::Pluggable::Object;

use List::Util qw /first/;
use Params::Util qw/_ARRAY/;

=head1 SYNOPSIS

=head2 using role and want behavior as MooX::Cmd

  package MyFoo;
  
  with MooX::Cmd::Role;
  
  sub _build_command_execute_from_new { 1 }

  package main;

  my $cmd = MyFoo->new_with_cmd;

=head2 using role and don't execute immediately

  package MyFoo;

  with MooX::Cmd::Role;
  use List::MoreUtils qw/ first_idx /;

  sub _build_command_base { "MyFoo::Command" }

  sub _build_command_execute_from_new { 0 }

  sub execute {
      my $self = shift;
      my $chain_idx = first_idx { $self == $_ } @{$self->command_chain};
      my $next_cmd = $self->command_chain->{$chain_idx+1};
      $next_cmd->owner($self);
      $next_cmd->execute;
  }

  package main;

  my $cmd = MyFoo->new_with_cmd;
  $cmd->command_chain->[-1]->run();

=head2 explicitely expression of some implicit stuff

  package MyFoo;

  with MooX::Cmd::Role;

  sub _build_command_base { "MyFoo::Command" }

  sub _build_command_execute_method_name { "run" }

  sub _build_command_execute_from_new { 0 }

  package main;

  my $cmd = MyFoo->new_with_cmd;
  $cmd->command_chain->[-1]->run();

=head1 DESCRIPTION

MooX::Cmd::Role is made for modern, flexible Moo style to tailor cli commands.

=head1 ATTRIBUTES

=head2 command_args

ARRAY-REF of args on command line

=cut

has 'command_args' => ( is => "ro" );

=head2 command_chain

ARRAY-REF of commands lead to this instance

=cut

has 'command_chain' => ( is => "ro" );

=head2 command_chain_end

COMMAND accesses the finally detected command in chain

=cut

has 'command_chain_end' => ( is => "lazy" );

sub _build_command_chain_end { $_[0]->command_chain->[-1] }

=head2 command_name

ARRAY-REF the name of the command lead to this command

=cut

has 'command_name' => ( is => "ro" );

=head2 command_commands

HASH-REF names of other commands 

=cut

has 'command_commands' => ( is => "lazy" );

sub _build_command_commands
{
	my ($class, %params) = @_;
	ref $class and $class = ref $class;
	my $base = defined $params{command_base} ? $params{command_base} : $class->_build_command_base(%params);

	# i have no clue why 'only' and 'except' seems to not fulfill what i need or are bugged in M::P - Getty
	my @cmd_plugins = grep {
		my $class = $_;
		$class =~ s/${base}:://;
		$class !~ /:/;
	} Module::Pluggable::Object->new(
		search_path => $base,
		require => 0,
	)->plugins;

	my %cmds;

	for my $cmd_plugin (@cmd_plugins) {
		$cmds{_mkcommand($cmd_plugin,$base)} = $cmd_plugin;
	}

	\%cmds;
}

=head2 command_base

STRING base of command plugins

=cut

has command_base => ( is => "lazy" );

sub _build_command_base
{
    my $class = shift;
    ref $class and $class = ref $class;
    return $class . '::Cmd'
}

=head2 command_execute_method_name

STRING name of the method to invoke to execute a command, default "execute"

=cut

has command_execute_method_name => ( is => "lazy" );

sub _build_command_execute_method_name { "execute" }

=head2 command_execute_return_method_name

STRING I have no clue what that is goood for ...

=cut

has command_execute_return_method_name => ( is => "lazy" );

sub _build_command_execute_return_method_name { "execute_return" }

=head2 command_creation_method_name

STRING name of constructor

=cut

has command_creation_method_name => ( is => "lazy" );

sub _build_command_creation_method_name { "new_with_cmd" }

=head2 command_creation_chain_methods

ARRAY-REF names of methods to chain for creating object (from L</command_creation_method_name>)

=cut

has command_creation_chain_methods => ( is => "lazy" );

sub _build_command_creation_chain_methods { ['new_with_options','new'] }

=head2 command_execute_from_new

BOOL true when constructor shall invoke L</command_execute_method_name>, false otherwise

=cut

has command_execute_from_new => ( is => "lazy" );

sub _build_command_execute_from_new { 0 }

=head1 METHODS

=head2 new_with_cmd

initializes by searching command line args for commands and invoke them

=cut

sub new_with_cmd
{
    goto &_initialize_from_cmd;
}

sub _mkcommand {
	my ( $package, $base ) = @_;
	$package =~ s/^${base}:://g;
	lc($package);
}

my @private_init_params = qw(command_base command_execute_method_name command_execute_return_method_name command_creation_chain_methods command_execute_method_name);

sub _initialize_from_cmd
{
	my ( $class, %params ) = @_;

	defined $params{command_execute_method_name} or $params{command_execute_method_name} = $class->_build_command_execute_method_name(%params);
	my $execute_method_name = $params{command_execute_method_name};

	my @moox_cmd_chain = defined $params{__moox_cmd_chain} ? @{$params{__moox_cmd_chain}} : ();

	my $opts_record = Data::Record->new({
		split  => qr{\s+},
		unless => $RE{quoted},
	});

	my @args = $opts_record->records(join(' ',@ARGV));
	my @used_args;
	my $cmd;

	defined $params{command_commands} or $params{command_commands} = $class->_build_command_commands(%params);
	while (my $arg = shift @args) {
		push @used_args, $arg and next unless $cmd = $params{command_commands}->{$arg};

		use_module( $cmd );
		$cmd->can($execute_method_name)
		  or croak "you need an '".$execute_method_name."' function in ".$cmd;
		last;
	}

	defined $params{command_creation_chain_methods} or $params{command_creation_chain_methods} = $class->_build_command_creation_chain_methods(%params);
	my @creation_chain = _ARRAY($params{command_creation_chain_methods}) ? @{$params{command_creation_chain_methods}} : ($params{command_creation_chain_methods});
	my $creation_method_name = first { $class->can($_) } @creation_chain;
	croak "cant find a creation method on " . $class unless $creation_method_name;
	my $creation_method = $class->can($creation_method_name); # XXX this is a perfect candidate for a new function in List::MoreUtils

	@ARGV = @used_args;
	$params{command_args} = [ @args ];
	$params{command_chain} = \@moox_cmd_chain; # later modification hopefully will modify ...
	$params{command_name} = $cmd;
	my $self = $creation_method->($class, %params);
	$cmd and push @moox_cmd_chain, $self;

	my @execute_return;

	defined $params{command_execute_return_method_name} or $params{command_execute_return_method_name} = $class->_build_command_execute_return_method_name(%params);
	if ($cmd) {
		@ARGV = @args;
		defined $params{command_creation_method_name} or $params{command_creation_method_name}  = $class->_build_command_creation_method_name(%params);
		my $creation_method = $cmd->can($params{command_creation_method_name});
		my $cmd_plugin;
		if ($creation_method) {
			my %cmd_create_params = %params;
			$cmd_create_params{__moox_cmd_chain} = \@moox_cmd_chain;
			delete @cmd_create_params{qw(command_commands), @private_init_params};
			$cmd_plugin = $creation_method->($cmd, %cmd_create_params);
			@execute_return = @{$cmd_plugin->{$params{command_execute_return_method_name}}};
		} else {
			$creation_method_name = first { $class->can($_) } @creation_chain;
			croak "cant find a creation method on " . $cmd unless $creation_method_name;
			$creation_method = $class->can($creation_method_name); # XXX this is a perfect candidate for a new function in List::MoreUtils
			$cmd_plugin = $creation_method->($cmd);
			defined $params{command_execute_from_new} or $params{command_execute_from_new} = $class->_build_command_execute_from_new(%params);
			$params{command_execute_from_new}
			  and @execute_return = $cmd_plugin->$execute_method_name(\@ARGV,\@moox_cmd_chain);
		}
	} else {
		defined $params{command_execute_from_new} or $params{command_execute_from_new} = $class->_build_command_execute_from_new(%params);
		$params{command_execute_from_new}
		  and @execute_return = $self->$execute_method_name(\@ARGV,\@moox_cmd_chain);
	}

	$self->{$params{command_execute_return_method_name}} = \@execute_return;

	return $self;
}

=head2 execute_return

returns the content of $self->{execute_return}

=cut

# XXX should be an r/w attribute - can be renamed on loading ...
sub execute_return { $_[0]->{execute_return} }

1;
