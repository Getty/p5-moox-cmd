package MooX::Cmd::Role::AbbrevCmds;
# ABSTRACT: Text::Abbrev support role for MooX::Cmd

use strict;
use warnings;

use Text::Abbrev;

use Moo::Role;

=description

When this role is applied, commands can be called by any unambiguous prefix.
For example, if your app has commands C<frobnicate> and C<format>, typing
C<frob> will match C<frobnicate>. Uses L<Text::Abbrev> internally.

Compose into your top-level command class alongside L<MooX::Cmd>:

  package MyApp;
  use Moo;
  use MooX::Cmd with_abbrev_cmds => 1;

Or apply the role explicitly:

  package MyApp;
  use Moo;
  with 'MooX::Cmd::Role';
  with 'MooX::Cmd::Role::AbbrevCmds';

=cut

requires "command_commands";

around _build_command_commands => sub {
    my $next     = shift;
    my $class    = shift;
    my $params   = shift;
    my $cmd_cmds = $class->$next($params, @_);

    my %abbrevs  = abbrev keys %$cmd_cmds;
    my %cmd_cmds = map { $_ => $cmd_cmds->{$abbrevs{$_}} } keys %abbrevs;

    return \%cmd_cmds;
};

1;
