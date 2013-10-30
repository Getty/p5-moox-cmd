package MooX::Cmd::Role;
# ABSTRACT: MooX cli app commands do this

use strict;
use warnings;

use Moo::Role;

use Carp;
use Module::Runtime qw/ use_module /;
use Regexp::Common;
use Data::Record;

use List::Util qw /first/;
use Params::Util qw/_ARRAY/;

=attribute command_args

ARRAY-REF of args on command line

=cut

has 'command_args' => ( is => "ro" );

=attribute command_chain

ARRAY-REF of commands lead to this instance

=cut

has 'command_chain' => ( is => "ro" );

=attribute command_name

ARRAY-REF the name of the command lead to this command

=cut

has 'command_name' => ( is => "ro" );

=attribute command_commands

HASH-REF names of other commands 

=cut

has 'command_commands' => ( is => "ro" );

sub _initialize_from_cmd
{
	my ( $class, %params ) = @_;

	my $cmd_create_options = delete $params{__cmd_create_options};
	my $execute_method_name = $cmd_create_options->{execute_method_name};

	my @moox_cmd_chain = defined $params{__moox_cmd_chain} ? @{$params{__moox_cmd_chain}} : ();

	my $opts_record = Data::Record->new({
		split  => qr{\s+},
		unless => $RE{quoted},
	});

	my @args = $opts_record->records(join(' ',@ARGV));
	my @used_args;
	my $cmd;

	while (my $arg = shift @args) {
		push @used_args, $arg and next unless $cmd = $params{command_commands}->{$arg};

		use_module( $cmd );
		$cmd->can($execute_method_name)
		  or croak "you need an '".$execute_method_name."' function in ".$cmd;
		last;
	}

	my @creation_chain = _ARRAY($cmd_create_options->{creation_chain_methods}) ? @{$cmd_create_options->{creation_chain_methods}} : ($cmd_create_options->{creation_chain_methods});
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

	my $execute_return_method_name = $cmd_create_options->{execute_return_method_name};
	if ($cmd) {
		@ARGV = @args;
		$creation_method_name = $cmd_create_options->{creation_method_name};
		my $creation_method = $cmd->can($creation_method_name);
		my $cmd_plugin;
		if ($creation_method) {
			my %cmd_create_params;
			$cmd_create_params{__moox_cmd_chain} = \@moox_cmd_chain;
			$cmd_plugin = $creation_method->($cmd, %cmd_create_params);
			@execute_return = @{$cmd_plugin->$execute_return_method_name};
		} else {
			$creation_method_name = first { $class->can($_) } @creation_chain;
			croak "cant find a creation method on " . $cmd unless $creation_method_name;
			$creation_method = $class->can($creation_method_name); # XXX this is a perfect candidate for a new function in List::MoreUtils
			$cmd_plugin = $creation_method->($cmd);
			$cmd_create_options->{execute_from_new}
			  and @execute_return = $cmd_plugin->$execute_method_name(\@ARGV,\@moox_cmd_chain);
		}
	} else {
		$cmd_create_options->{execute_from_new}
		  and @execute_return = $self->$execute_method_name(\@ARGV,\@moox_cmd_chain);
	}

	$self->{$execute_return_method_name} = \@execute_return;

	return $self;
}

1;
