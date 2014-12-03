#!perl

## in a separate test file

use strict;
use warnings;

use Test::More;
use Test::Kwalitee 'kwalitee_ok';

kwalitee_ok(qw(-use_strict));

done_testing;
