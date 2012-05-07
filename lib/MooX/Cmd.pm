package MooX::Cmd;
# ABSTRACT: Giving an easy Moo style way to make command organized CLI apps

use strict;
use warnings;
use Carp;
use Module::Pluggable::Object;
use Regexp::Common;
use Data::Record;
use Package::Stash;

my %DEFAULT_OPTIONS = (
	'creation_chain_methods' => ['new_with_options','new'],
	'creation_method_name' => 'new_with_cmd',
	'execute_return_method_name' => 'execute_return',
	'execute_method_name' => 'execute',
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
	my $execute_return_method_name = $import_options{execute_return_method_name};
	my $execute_method_name = $import_options{execute_method_name};
	my $base = $import_options{base} ? $import_options{base} : ($caller.'::Cmd');
	my @creation_chain = ref $import_options{creation_chain_methods} eq 'ARRAY' ? @{$import_options{creation_chain_methods}} : ($import_options{creation_chain_methods});

	# i have no clue why 'only' and 'except' seems to not fulfill what i need or are bugged in M::P - Getty
	my @cmd_plugins = grep {
		croak "you need an '".$execute_method_name."' function in ".$_ unless $_->can($execute_method_name);
		my $class = $_;
		$class =~ s/${base}:://g;
		$class =~ /:/ ? 0 : 1;
	} Module::Pluggable::Object->new(
		search_path => $base,
		require => 1,
	)->plugins;
	
	my $stash = Package::Stash->new($caller);

	$stash->add_symbol('&'.$execute_return_method_name, sub { shift->{$execute_return_method_name} });
	$stash->add_symbol('&'.$import_options{creation_method_name}, sub {
		my ( $class, %params ) = @_;

		my @moox_cmd_chain = defined $params{__moox_cmd_chain} ? @{$params{__moox_cmd_chain}} : ();
		
		my %create_params;

		my %cmds;
		
		for my $cmd_plugin (@cmd_plugins) {
			$cmds{_mkcommand($cmd_plugin,$base)} = $cmd_plugin;
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
	});

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


