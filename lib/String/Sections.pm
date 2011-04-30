use strict;
use warnings;

package String::Sections;
BEGIN {
  $String::Sections::VERSION = '0.1.0'; # TRIAL
}

# ABSTRACT: Extract labelled groups of sub-strings from a string.


use 5.010001;



# Internal utility functions prefixed by __

sub __require {
  my ($package) = shift;

  # Wrapper for all local calls to 'require' that allows us to add a warning statement
  # the first time it is called.
  #
  # This is mostly for development purposes and will likely be elimiated in future.
  # -- Kent\n 2011-04-30
  state $loaded;
  $loaded //= {};
  exists $loaded->{$package} or $loaded->{$package} = do {
    $package =~ s{::}{/}gmsx;
    $package .= '.pm';
    require $package;

    # This is here for lazy-loading checking, but commented out for releases.
    # warn "Loaded $_[0]";
    1;
  };
  return 1;
}

# These stubs exist to lazy-load and redirect to the necessary functions.

sub __subname {

  # This code section exists to add sub routine names to various internal bits
  # to improve clarity of backtraces during development,
  # but are commented out for non-development releases, and may be permenantly
  # removed in a future release -- Kent\n 2011-04-30
  #__require 'Sub::Name';
  #goto &Sub::Name::subname;
}

sub __blessed {
  __require 'Scalar::Util';
  goto &Scalar::Util::blessed;
}

sub __package_stash {
  __require 'Package::Stash';
  return Package::Stash->new(__PACKAGE__);
}

sub __confess {
  __require 'Carp';
  goto &Carp::confess;
}

sub __check_regexp {
  __require 'Params::Classify';
  goto &Params::Classify::check_regexp;
}

sub __check_string {
  __require 'Params::Classify';
  goto &Params::Classify::check_string;
}

## Internal method that curries all package functions passed to it
# so that they check that they're called as a method.
#
# Likely removed in a future release, or possibly replaced with something else.
# -- Kent\n 2011-04-30

sub __method_list {
  my (@methods) = @_;
  my $stash = __package_stash();
  for my $methodname (@methods) {
    my $symbolname = q{&} . $methodname;
    __confess("No such method to curry $methodname") if not $stash->has_symbol($symbolname);
    my $method  = $stash->get_symbol($symbolname);
    my $checker = sub {
      goto $method if __blessed( $_[0] );
      __confess("Called method $methodname as a function, Argument 0 is expected to be a blessed object");
    };
    __subname( $methodname . '<check:method>', $checker );
    $stash->remove_symbol($symbolname);
    $stash->add_symbol( $symbolname, $checker );
  }
  return 1;
}

## Roll-your-own-attribute generator.
#
# Might be replaced/removed in a future release, but depends.
#
# __attr_list(sub{
#   return sub { $validation_code },
#  } @attribute_names );
#
#  Attributes:
#   1. Have an accessor/mutator with a matching name, which validates
#      paramters passed to it when used as a setter.
#   2. Have an internal method with a matching name with a leading _
#      that populates the attributes value in the stash either from
#      _default_{$attribute_name} or the arguments passed during construction.
#      ( with validation )

sub __attr_list {
  my ( $validator_generator, @attrs ) = @_;
  my $stash = __package_stash();
  for my $attr (@attrs) {

    my $validator = $validator_generator->();

    my $internal_name       = '_' . $attr;
    my $mutator_name        = $attr;
    my $default_method_name = '_default_' . $attr;
    my $fieldname           = $attr;

    __subname( $fieldname . '<check:validate_value>', $validator );

    $stash->add_symbol(
      q{&} . $mutator_name => sub {
        my ( $self, @args ) = @_;
        if (@args) {
          my ($value) = $args[0];
          {
            local $_ = $value;
            $validator->($_);
          }
          $self->{$fieldname} = $value;
        }
        return $self->can($internal_name)->($self);
      }
    );

    $stash->add_symbol(
      q{&} . $internal_name => sub {
        my ($self) = @_;
        return $self->{$fieldname} if exists $self->{$fieldname};
        if ( not exists $self->{args} or not exists $self->{args}->{$fieldname} ) {
          $self->{$fieldname} = $self->can($default_method_name)->($self);
          return $self->{$fieldname};
        }
        {
          local $_ = $self->{args}->{$fieldname};
          $validator->($_);
        }
        $self->{$fieldname} = $self->{args}->{$fieldname};
        return $self->{$fieldname};
      }
    );
  }
  return 1;
}


sub new {
  my ( $class, %args ) = @_;

  $class = __blessed($class) if __blessed($class);

  my $config = {};

  $config->{args} = \%args if %args;

  my $object = bless $config, $class;
  return $object;
}


sub load_list {
  my ( $self, @rest ) = @_;
  @rest = @{ $rest[0] } if ref $rest[0] and ref $rest[0] eq 'ARRAY';
  my %stash;
  my $current;

  if ( $self->_default_name ) {
    my $blank = q{};
    $current = $self->_default_name;
    $stash{ $self->_default_name } = \$blank;
  }

LINE: for my $line (@rest) {

    if ( $line =~ $self->_header_regex ) {
      my $blank = q{};
      $current = $1;
      $stash{$current} = \$blank;
      next LINE;
    }

    # not valid for lists because lists are not likely to have __END__ in them.
    if ( $self->_stop_at_end ) {
      last LINE if $line =~ $self->_document_end_regex;
    }

    if ( $self->_ignore_empty_prelude ) {
      next LINE if not defined $current and $line =~ $self->_empty_line_regex;
    }

    if ( not defined $current ) {
      __confess(
        'bogus data section: text outside named section. line: ' . $line

          #. ' self: ' . dump $self
      );
    }

    if ( $self->_enable_escapes ) {
      my $regex = $self->_line_escape_regex;
      $line =~ s{$regex}{}msx;
    }

    ${ $stash{$current} } .= $line;
  }

  $self->{stash}     = \%stash;
  $self->{populated} = 1;
  return 1;
}


sub load_string {
  my ( $self, $string ) = @_;
  return __confess('Not Implemented');
}


sub load_filehandle {
  my ( $self, $fh ) = @_;
  return __confess('Not implemented');
}


sub merge {
  my ( $self, $other ) = @_;
  return __confess('Not Implemented');
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

# Internal check for all things that refer to the sections stash.

sub _sections {
  my ($self) = @_;
  if ( not defined $self->{populated} or not $self->{populated} ) {
    __confess('Called to a section fetcher without first populating the section stash');
  }
  return $self->_stash;
}

# Stash vivifier.

sub _stash {
  my ($self) = @_;
  return $self->{stash} if exists $self->{stash};
  $self->{stash} = {};
  return $self->{stash};
}

# Stash key value setter. Not yet used anywhere.

sub _store_stash {
  my ( $self, $key, $value ) = @_;
  $self->_stash->{$key} = $value;
  return $value;
}

#
# Defines accessors *_regex and _*_regex , that are for public and private access respectively.
# Defaults to _default_*_regex.
#
__attr_list(
  sub {
    sub { __check_regex($_) }
  },
  qw( header_regex empty_line_regex document_end_regex line_escape_regex )
);

# String | Undef accessors.
#
__attr_list(
  sub {
    sub { not defined $_ or __check_string($_) }
  },
  qw( default_name ),
);

# Boolean Accessors
__attr_list(
  sub {
    sub { 1; }
  },
  qw( stop_at_end ignore_empty_prelude enable_escapes ),
);

# Go through all these methods and curry them to do method checks.

__method_list(
  qw(
    load_list load_string load_filehandle merge section_names has_section section _sections _stash _store_stash
    header_regex _header_regex
    empty_line_regex _empty_line_regex
    document_end_regex _document_end_regex
    line_escape_regex  _line_escape_regex
    default_name _default_name
    stop_at_end _stop_at_end
    ignore_empty_prelude _ignore_empty_prelude
    enable_escapes _enable_escapes
    )
);

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

version 0.1.0

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

TODO

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

=item * Rolls its own OO

Because I didn't want to use Moose or anything that would likely be XS dependent
for the sake of speed , memory consumption, dependency complexity, and portability.

This may change in a future release but you shouldn't care too much.

=item * Some weird code

Mostly the lazy-loading stuff to reduce memory consumption that isn't necessary
and reduce load time on systems where File IO is slow. ( As IO is one of those bottlenecks
that's hard to optimise without simply eliminating IO ).

There's some commented out things that are there mostly for use during development,
such as using Sub::Name to label things for debugging, but are commented out to eliminate
its XS dependency on deployed installs.

Some of the Lazy-Loaded modules implicitly need XS things, like Params::Classify, but they're only
required for user specified parameter validation, and will not be either loaded or needed unless you
wish to deviate from the defaults. ( And even then you can do this without needing XS, just parameters will not
be validated ).

But these weirdnesses are largely experimental parts that are likely to be factored out at a later stage
if we don't need them any more.

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

