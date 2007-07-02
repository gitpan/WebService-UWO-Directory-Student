# WebService::UWO::Directory::Student
#  Perform lookups using the University of Western Ontario's student directory
#
# Copyright (C) 2006-2007 by Jonathan Yu <frequency@cpan.org>
#
# Redistribution  and use in source/binary forms, with or without  modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
# 2. Redistributions  in binary form must  reproduce the above copyright notice,
#    this list of  conditions and the  following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 3. Neither  the name  of the  University of Western Ontario (Canada)  nor  the
#    names  of  its  contributors  may be used to  endorse  or promote  products
#    derived from this software without specific prior written permission.
#
# This software is  provided by the copyright  holders and contributors  "AS IS"
# and ANY  EXPRESS  OR IMPLIED  WARRANTIES, including, but  not limited  to, the
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED.
#
# In  no event  shall  the copyright  owner  or  contributors  be liable for any
# direct,  indirect,  incidental,  special,  exemplary or  consequential damages
# (including, but  not limited to, procurement of  substitute goods or services;
# loss of use, data or profits;  or business interruption) however caused and on
# any  theory of  liability,  whether in  contract,  strict  liability  or  tort
# (including  negligence or otherwise) arising in any way out of the use of this
# software, even if advised of the possibility of such damage.

package WebService::UWO::Directory::Student;

use strict;
use warnings;

use LWP::UserAgent;

=head1 NAME

WebService::UWO::Directory::Student - Perform lookups using the University of
Western Ontario's student directory

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module provides a Perl interface to the public directory search system
which lists current students, staff and faculty at the University of Western
Ontario. (http://uwo.ca/westerndir/index.html)

This module is only able to access partial student records since students
must give consent for their contact information to be published on the web.
(http://uwo.ca/westerndir/index-student.html).

For a more complete module able to search staff and faculty records as well,
please consider using C<WebService::UWO::Directory>.

Example code:

    use WebService::UWO::Directory::Student;

    # Create Perl interface to API
    my $dir = WebService::UWO::Directory::Student->new;

    # Look up a student by name
    my $results = $dir->lookup({
                                first => 'John',
                                last  => 'S'
                               });

    # Go through results
    foreach my $rec (@{$results}) {
      print 'email: ' . $rec->{email} . "\n";
    }

    # Reverse a lookup (use e-mail to find record)
    my $reverse = $dir->lookup({
                                email => 'jsmith@uwo.ca'
                               });

=head1 FUNCTIONS

=head2 new(\%params)

Creates a C<WebService::UWO::Directory::Student> search object, which uses
a given web page and server. Being that this is a specialized module, the
default parameters should suffice.

The parameters available are:
    my $dir = WebService::UWO::Directory::Student->new({
                                                        url    => 'http://uwo.ca/cgi-bin/dsgw/whois2html2',
                                                        server => 'localhost',
                                                       });

Which instantiates a C<WebService::UWO::Directory::Student> instance using
C<url> as the frontend and C<server> as the "black-box" backend.

=cut

sub new {
  my ($class, $params) = @_;

  my $self = {
    url       => $params->{url} || 'http://uwo.ca/cgi-bin/dsgw/whois2html2',
    server    => $params->{server} || 'localhost',
  };

  bless($self, $class);
}

=head2 lookup(\%params)

Uses a C<WebService::UWO::Directory::Student> search object to locate a
given person based on either their name (C<first> and/or C<last>) or their
address (C<email>).

Example code:
    # Look up "John S" in the student directory
    my $results = $dir->lookup({
                                first => 'John',
                                last  => 'S'
                               });

    # Look up jsmith@uwo.ca
    my $reverse = $dir->lookup({
                                email => 'jsmith@uwo.ca'
                               });

This method is not guaranteed to return results. If no results are found,
the return code will be 0.

In the case of a name-based lookup, the results will be returned as a
reference pointing to an ARRAY containing HASH references. Each of these
hashes represents a single user entry.

In the case of an e-mail reverse lookup, a single HASH reference will be
returned.

=cut

sub lookup {
  my ($self, $params) = @_;

  die 'Parameter not a hash reference!' unless ref($params) eq 'HASH';

  die 'Need at least one parameter (first name, last name or e-mail address)'
    unless(
      exists($params->{first}) ||
      exists($params->{last})  ||
      exists($params->{email})
    );

  my $query;
  if (exists($params->{email})) {
    if ($params->{email} =~ m/^(\w+)(\@uwo\.ca)?$/) {
      $query = $1;
    }
    else {
      die 'Need a UWO username or e-mail address on the uwo.ca domain';
    }

    # Discover query by deconstructing the username
    #  jdoe32
    #   First name: j
    #   Last name:  doe
    #   E-mail:     jdoe32@uwo.ca
    if ($query =~ /^(\w)([^\d]+)([\d]*)$/) {
      my $results = $self->lookup({ first => $1, last => $2 });
      foreach my $record (@{$results}) {
        if ($record->{email} eq $params->{email}) {
          return $record;
        }
      }
    }
    else {
      die 'Failed to parse the username!';
    }
  }
  else {
    if (!exists($params->{first})) {
      $query = $params->{last} . ',';
    }
    elsif (!exists($params->{last})) {
      $query = $params->{first} . '.';
    }
    else {
      $query = $params->{last} . ',' . $params->{first};
    }

    my $data = $self->_query($query);

    return $self->_parse($data);
  }
  return 0;
}

=head2 lookup_reverse($email)

This method is a wrapper around the standard "lookup" method.

Example code:
    # Look up jsmith@uwo.ca
    my $reverse = $dir->lookup_reverse('jsmith@uwo.ca');

is equivalent to

    # Look up jsmith@uwo.ca
    my $reverse = $dir->lookup({
                                email => 'jsmith@uwo.ca'
                               });

This method is not guaranteed to return results. If no results are found,
the return code will be 0.

=cut

sub lookup_reverse {
  my ($self, $addr) = @_;
  return $self->lookup({ email => $addr });
}

=head UNSUPPORTED API

C<WebService::UWO::Directory::Student> provides access to some internal
methods used to retrieve and process raw data from the directory server.
Its behaviour is subject to change and may be finalized later as the
need arises.

=head2 _query($query)

This method performs an HTTP lookup using C<LWP::UserAgent> and returns
a SCALAR reference to the returned page content.

=cut

sub _query {
  my ($self, $query) = @_;

  my $ua = LWP::UserAgent->new;

  my $r = $ua->post($self->{url},
  {
    server => $self->{server},
    query  => $query,
  });

  die 'Error reading response: ' . $r->status_line unless $r->is_success;

  return \$r->content;
}

=head2 _parse($response)

This method processes the HTML content retrieved by _query method and
returns an ARRAY reference containing HASH references to the result set.

=cut

sub _parse {
  my ($self, $response) = @_;

  #    Full Name: Last,First Middle
  #       E-mail: e-mail@uwo.ca
  # Registered In: Faculty Name
  my @matches = (${$response} =~ m{Full Name: ([^,]+),(.+)\n       E-mail: .*\>(.+)\</A\>\nRegistered In: (.+)}g);
  # 4 fields captured

  my @results;
  for (my $i = 0; $i < scalar(@matches); $i += 4) {
    my $record = {
      last      => $matches[$i],
      first     => $matches[$i+1],
      email     => $matches[$i+2],
      faculty   => $matches[$i+3]
    };
    push(@results, $record);
  }

  return \@results;
}

1;
