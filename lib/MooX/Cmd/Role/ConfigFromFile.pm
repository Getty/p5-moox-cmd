package MooX::Cmd::Role::ConfigFromFile;
# ABSTRACT: MooX::ConfigFromFile support role for MooX::Cmd
our $VERSION = '1.001';
use strict;
use warnings;

use Moo::Role;

=description

Extends L<MooX::ConfigFromFile::Role> config prefix support to include the
current command chain. Each command name in the chain is appended to the
config prefixes, allowing per-command configuration file sections.

Enable via L<MooX::Cmd>:

  package MyApp;
  use Moo;
  use MooX::Cmd with_config_from_file => 1;

This will automatically compose both L<MooX::ConfigFromFile::Role> and this
role into your command classes.

=seealso

L<MooX::ConfigFromFile>

=cut

requires "config_prefixes";

around _build_config_prefixes => sub {
    my $next     = shift;
    my $class    = shift;
    my $params   = shift;
    my $cfg_pfxs = $class->$next($params, @_);

    ref $params->{command_chain} eq "ARRAY"
      and push @{$cfg_pfxs},
      grep { defined $_ } map { $_->command_name } grep { $_->can("command_name") } @{$params->{command_chain}};

    return $cfg_pfxs;
};

1;
