package Interchange6;

=head1 NAME

Interchange6 - Open Source Shop Machine

=head1 VERSION

0.011

=cut

our $VERSION = '0.011';

=head1 DESCRIPTION

Interchange6, the Open Source Shop Machine, is the Modern Perl ecosystem
for online business.
It uses the L<DBIx::Class> database schema L<Interchange6::Schema>.

This module provides the following APIs:

=over 4

=item Carts

L<Interchange6::Cart>

=back

To build your own business website, please take a look at
our Dancer plugin: L<Dancer::Plugin::Interchange6>.

=head1 CART

Interchange6 supports multiple carts, automatic collapsing of similar items
and price caching.

=head1 CAVEATS

Please anticipate API changes in this early state of development.

=head1 AUTHOR

Stefan Hornburg (Racke), C<racke@linuxia.de>

=head1 CONTRIBUTORS

Peter Mottram C<peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2014 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
