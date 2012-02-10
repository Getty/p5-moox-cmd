package MooX::Cmd;
# ABSTRACT: Giving an easy Moo style way to make command organized CLI apps

use strict;
use warnings;
use Carp;
use Module::Pluggable::Object;
use Regexp::Common;
use Data::Record;

my %DEFAULT_OPTIONS = (
	'creation_chain_methods' => ['new_with_options','new'],
	'creation_method_name' => 'new_with_cmd',
	'execute_return_method_name' => 'execute_return',
	'execute_method_name' => 'execute',
	'command_method_name' => 'command',
	'search_path' => undef,
);

sub _mkcommand {
	my ( $package, $search_path ) = @_;
	$package =~ s/^${search_path}:://g;
	lc($package);
}

sub _uniq {
	my %seen = ();
	my @r = ();
	foreach my $a (@_) {
		unless ($seen{$a}) {
			push @r, $a;
			$seen{$a} = 1;
		}
	}
	return @r;
}

sub import {
	my ( undef, %import_params ) = @_;
	my ( %import_options ) = ( %DEFAULT_OPTIONS, %import_params );
	my $caller = caller;
	my $execute_return_method_name = $import_options{execute_return_method_name};
	my $execute_method_name = $import_options{execute_method_name};
	my $command_method_name = $import_options{command_method_name};
	my $search_path = $import_options{search_path} ? $import_options{search_path} : ($caller.'::Cmd');
	my @creation_chain = ref $import_options{creation_chain_methods} eq 'ARRAY' ? @{$import_options{creation_chain_methods}} : ($import_options{creation_chain_methods});

	my @cmd_plugins = Module::Pluggable::Object->new(
		search_path => $search_path,
		inner => 0,
		require => 1,
	)->plugins;

	my %cmd_plugin_commands;
	
	for (@cmd_plugins) {
		croak "you need an '".$execute_method_name."' function in ".$_ unless $_->can($execute_method_name);
		$cmd_plugin_commands{$_} = [];
	}
	
	{

		no strict 'refs';
		*{"${caller}::$command_method_name"} = sub {
			my ( $command ) = @_;
			push @{$cmd_plugin_commands{$caller}}, $command;
		}

	}

	{

		no strict 'refs';
		*{"${caller}::$execute_return_method_name"} = sub { shift->{$execute_return_method_name} }

	}

	{

		no strict 'refs';
		*{"${caller}::$import_options{creation_method_name}"} = sub {
			my ( $class, %params ) = @_;

			my @moox_cmd_chain = defined $params{__moox_cmd_chain} ? @{$params{__moox_cmd_chain}} : ();
			
			my %create_params;

			my %cmds;
			
			for my $cmd_plugin (keys %cmd_plugin_commands) {
				if (@{$cmd_plugin_commands{$cmd_plugin}}) {
					for (@{$cmd_plugin_commands{$cmd_plugin}}) {
						$cmds{$_} = $cmd_plugin;
					}
				} else {
					$cmds{_mkcommand($cmd_plugin,$search_path)} = $cmd_plugin;
				}
			}
			
			my $opts_record = Data::Record->new({
				split  => qr{\s+},
				unless => $RE{quoted},
			});

			my @args = $opts_record->records(join(' ',@ARGV));
	
			my @used_args;
			
			my $cmd;
		
			while (my $arg = shift @args) {
				if (defined $cmds{$arg}) {
					$cmd = $cmds{$arg};
					last;
				} else {
					push @used_args, $arg;
				}
			}
			
			my $creation_method;
			for (@creation_chain) {
				$creation_method = $caller->can($_);
				last if $creation_method;
			}
			
			@ARGV = @used_args;
			my $self = $creation_method->($class, %params);
			
			my @execute_return;
			
			if ($cmd) {
				@ARGV = @args;
				push @moox_cmd_chain, $self;
				my %cmd_create_params = defined $create_params{$cmd} ? %{$create_params{$cmd}} : ();
				my $creation_method_name = $import_options{creation_method_name};
				my $creation_method = $cmd->can($creation_method_name);
				my $cmd_plugin;
				if ($creation_method) {
					$cmd_create_params{__moox_cmd_chain} = \@moox_cmd_chain;
					$cmd_plugin = $creation_method->($cmd, %cmd_create_params);
					@execute_return = @{$cmd_plugin->$execute_return_method_name};
				} else {
					for (@creation_chain) {
						if ($creation_method = $cmd->can($_)) {
							$cmd_plugin = $creation_method->($cmd, %cmd_create_params);
							last;
						}
					}
					croak "cant find a creation method on ".$cmd unless $creation_method;
					@execute_return = $cmd_plugin->$execute_method_name(\@ARGV,\@moox_cmd_chain);
				}
			} else {
				@execute_return = $self->$execute_method_name(\@ARGV,\@moox_cmd_chain);
			}

			$self->{$execute_return_method_name} = \@execute_return;
			
			return $self;
		}

	}

}

1;

=encoding utf8

=head1 SYNOPSIS
 
=head1 DESCRIPTION

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-moox-cmd
  Pull request and additional contributors are welcome
 
Issue Tracker

  http://github.com/Getty/p5-moox-cmd/issues


