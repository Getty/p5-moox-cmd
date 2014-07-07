
requires 'Moo', '0.009013';
requires 'Regexp::Common', '2011121001';
requires 'Module::Pluggable', '4.8';
requires 'Package::Stash', '0.33';
requires 'Params::Util', '0.37';
requires 'Text::ParseWords', '0';
requires 'IO::TieCombine', '0';

on test => sub {
  requires 'Test::More', '0.98';
};
