use strict;
use warnings;

package String::Sections;
BEGIN {
  $String::Sections::VERSION = '0.1.1'; # TRIAL
}

# ABSTRACT: Extract labelled groups of sub-strings from a string.


use 5.010001;
use Moo;
use Sub::Quote qw{ quote_sub };




sub __add_line {

  my ( $self, $stash, $line, $current ) = @_;

  if ( ${$line} =~ $self->header_regex ) {
    my $blank = q{};
    ${$current} = $1;
    $stash->{ ${$current} } = \$blank;
    return 1;    # 1 is next.
  }

  # not valid for lists because lists are not likely to have __END__ in them.
  if ( $self->stop_at_end ) {
    return 0 if ${$line} =~ $self->document_end_regex;
  }

  if ( $self->ignore_empty_prelude ) {
    return 1 if not defined ${$current} and ${$line} =~ $self->empty_line_regex;
  }

  if ( not defined ${$current} ) {
    require Carp;
    Carp::confess(
      'bogus data section: text outside named section. line: ' . ${$line}

        #. ' self: ' . dump $self
    );
  }

  if ( $self->enable_escapes ) {
    my $regex = $self->line_escape_regex;
    ${$line} =~ s{$regex}{}msx;
  }

  ${ $stash->{ ${$current} } } .= ${$line};

  return 1;
}


sub load_list {
  my ( $self, @rest ) = @_;
  @rest = @{ $rest[0] } if ref $rest[0] and ref $rest[0] eq 'ARRAY';
  my %stash;
  my $current;

  if ( $self->default_name ) {
    my $blank = q{};
    $current = $self->default_name;
    $stash{ $self->default_name } = \$blank;
  }

  for my $line (@rest) {
    my $result = __add_line( $self, \%stash, \$line, \$current );
    next if $result;
    last if not $result;

  }
  $self->_sections( \%stash );
  return 1;
}


sub load_string {
  my ( $self, $string ) = @_;
  require Carp;
  return Carp::confess('Not Implemented');
}


sub load_filehandle {
  my ( $self, $fh ) = @_;
  my %stash;
  my $current;

  if ( $self->_default_name ) {
    my $blank = q{};
    $current = $self->_default_name;
    $stash{ $self->_default_name } = \$blank;
  }
  while ( defined( my $line = <$fh> ) ) {
    my $result = __add_line( $self, \%stash, \$line, \$current );
    next if $result;
    last if not $result;
  }

  $self->_sections( \%stash );
  return 1;

}


sub merge {
  my ( $self, $other ) = @_;
  require Carp;
  return Carp::confess('Not Implemented');
}


sub section_names {
  my ($self) = @_;
  return keys %{ $self->_sections };
}


sub has_section {
  my ( $self, $section ) = @_;
  return exists $self->_sections->{$section};
}


sub section {
  my ( $self, $section ) = @_;
  return $self->_sections->{$section};
}

## no critic( RequireInterpolationOfMetachars )
has '_sections' => (
  is      => 'rw',
  isa     => quote_sub(q{ if ( ref $_[0] ne 'HASH' ){ require Carp; Carp::confess('_sections must be a hash'); } }),
  lazy    => 1,
  default => quote_sub(q{ require Carp; Carp::confess('tried to get data from sections without first populating with data');}),
);

#
# Defines accessors *_regex and _*_regex , that are for public and private access respectively.
# Defaults to _default_*_regex.

for (qw( header_regex empty_line_regex document_end_regex line_escape_regex )) {
  has $_ => (
    is      => 'rw',
    isa     => quote_sub(q| require Params::Classify; Params::Classify::check_regexp( $_[0] ) |),
    builder => '_default_' . $_,
    lazy    => 1,
  );
}

# String | Undef accessors.
#

for (qw( default_name )) {

  has $_ => (
    is      => 'rw',
    isa     => quote_sub(q| if( defined  $_[0] ){  require Params::Classify; Params::Classift::check_string( $_[0] ); } |),
    builder => '_default_' . $_,
    lazy    => 1,
  );
}

# Boolean Accessors
for (qw( stop_at_end ignore_empty_prelude enable_escapes )) {
  has $_ => (
    is      => 'rw',
    isa     => quote_sub(q|  if( ref $_[0] ){ require Carp; Carp::confess("$_[0] is not a valid boolean value"); }  |),
    builder => '_default_' . $_,
    lazy    => 1,
  );
}

# Go through all these methods and curry them to do method checks.

for (
  qw(
  load_list load_string load_filehandle merge section_names has_section section _sections
  stop_at_end ignore_empty_prelude enable_escapes
  default_name
  header_regex empty_line_regex document_end_regex line_escape_regex
  )
  )
{
  before $_ =>
    quote_sub(q| require Scalar::Util; if ( not Scalar::Util::blessed($_[0]) ){ require Carp; Carp::confess("Called method |
      . $_
      . q| as a function, Argument 0 is expected to be a blessed object");} | );
}

# Default values for various attributes.

sub _default_header_regex {
  return qr{
    \A                # start
      _+\[            # __[
        \s*           # any whitespace
          ([^\]]+?)   # this is the actual name of the section
        \s*           # any whitespace
      \]_+            # ]__
      [\x0d\x0a]{1,2} # possible cariage return for windows files
    \z                # end
    }msx;
}

sub _default_empty_line_regex {
  return qr{
      ^
      \s*   # Any empty lines before the first section get ignored.
      $
  }msx;
}

sub _default_document_end_regex {
  return qr{
    ^          # Start of line
    __END__    # Document END matcher
  }msx;
}

sub _default_line_escape_regex {
  return qr{
    \A  # Start of line
    \\  # A literal \
  }msx;
}

sub _default_default_name { return }

sub _default_stop_at_end { return }

sub _default_ignore_empty_prelude { return 1 }

sub _default_enable_escapes { return }

1;

__END__
=pod

=head1 NAME

String::Sections - Extract labelled groups of sub-strings from a string.

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

  use String::Sections;

  my $sections = String::Sections->new();
  $sections->load_list( @lines );
  # TODO
  # $sections->load_string( $string );
  # $sections->load_filehandle( $fh );
  #
  # $sections->merge( $other_sections_object );

  my @section_names = $sections->section_names();
  if ( $sections->has_section( 'section_label' ) ) {
    my $string_ref = $sections->section( 'section_label' );
    ...
  }

=head1 DESCRIPTION

Data Section sports the following default data markup

  __[ somename ]__
  Data
  __[ anothername ]__
  More data

This module is designed to behave as a work-alike, except on already extracted string data.

=head1 METHODS

=head2 new

=head2 new( %args )

  my $object = String::Sections->new();

  my $object = String::Sections->new( attribute_name => 'value' );

=head2 load_list

=head2 load_list ( @strings )

=head2 load_list ( \@strings )

  my @strings = <$fh>;

  $object->load_list( @strings );

  $object->load_list( \@strings );

This method handles data as if it had been slopped in unchomped from a filehandle.

Ideally, each entry in @strings will be terminated with $/ , as the collated data from each section
is concatenated into a large singular string, e.g.:

  $object->load_list("__[ Foo ]__\n", "bar\n", "baz\n" );
  $object->section('Foo')
  # bar
  # baz

  $object->load_list("__[ Foo ]__\n", "bar", "baz" );
  $object->section('Foo');
  # barbaz

  $object->load_list("__[ Foo ]__", "bar", "baz" ) # will not work by default.

This behaviour may change in the future, but this is how it is with the least effort for now.

=head2 load_string

TODO

=head2 load_filehandle

=head2 load_filehandle( $fh )

  $object->load_filehandle( $fh )

=head2 merge

TODO

=head2 section_names

  my @names = $object->section_names;

Returns a list of the sections that have been extracted so far.

=head2 has_section

=head2 has_section( $name )

  if( $object->has_section('Foo') ){
    # code
  }

Determines if the given section name has been extracted.

=head2 section

=head2 section( $name )

  my $str = $object->section('Foo');

  print ${ $str };

This returns a B<REFERENCE> to a String that was parsed from section "Foo".

=head1 DEVELOPMENT

This code is still new and under development.

All the below facets are likely to change at some point, but don't
largely contribute to the API or usage of this module.

=over 4

=item * Needs Perl 5.10.1

To make some of the development features easier.

=back

=head1 Recommended Use with Data::Handle

This modules primary inspiration is Data::Section, but intending to split and decouple many of the
internal parts to add leverage to the various behaviors it contains.

Data::Handle solves part of a problem with Perl by providing a more reliable interface to the __DATA__ section in a file that is not impeded by various things that occur if its attempted to be read more than once.

In future, I plan on this being the syntax for connecting Data::Handle with this module to emulate Data::Section:

  my $dh = Data::Handle->new( __PACKAGE__ );
  my $ss = String::Sections->new( stop_at_end => 1 );
  $ss->load_filehandle( $dh );

This doesn't implicitly perform any of the inheritance tree magic Data::Section does,
but its also planned on making that easy to do when you want it with C<< ->merge( $section ) >>

For now, the recommended code is not so different:

  my $dh = Data::Handle->new( __PACKAGE__ );
  my $ss = String::Sections->new( stop_at_end => 1 );
  $ss->load_list( <$dh> );

Its just somewhat less efficient.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

