#!/usr/bin/perl -T

# t/03live.t
#  Module live functionality tests (requires Internet connectivity)
#
# $Id: 03live.t 8216 2009-07-25 22:16:50Z FREQUENCY@cpan.org $

use strict;
use warnings;

use Test::More;

use WebService::UWO::Directory::Student;

unless ($ENV{HAS_INTERNET}) {
  plan skip_all => 'Set HAS_INTERNET to enable tests requiring Internet';
}

plan tests => 8;

my $dir = WebService::UWO::Directory::Student->new;

# Normal lookup functionality
my $res = $dir->lookup({
  first => 'Joyce',
  last  => 'Peralta',
});

is($res->[0]->{given_name}, 'Joyce Mae', 'User found by name');
is($res->[0]->{last_name},  'Peralta');
is($res->[0]->{email},      'jperalt2@uwo.ca');
is($res->[0]->{faculty},    'Faculty of Info & Media Stds');

# Reverse lookup functionality
$res = $dir->lookup({
  email => 'jperalt2@uwo.ca',
});

is($res->{given_name}, 'Joyce Mae', 'User found by email');
is($res->{last_name},  'Peralta');
is($res->{email},      'jperalt2@uwo.ca');
is($res->{faculty},    'Faculty of Info & Media Stds');
