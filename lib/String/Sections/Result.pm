use strict;
use warnings;

package String::Sections::Result;

# ABSTRACT: Glorified wrapper around a hash representing a parsed String::Sections result
#

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"String::Sections::Result",
    "interface":"class",
    "inherits":"Moo::Object"
}

=end MetaPOD::JSON

=cut

use Moo 1.000008;

## no critic (RequireArgUnpacking)

sub _croak   { require Carp;         goto &Carp::croak; }
sub _blessed { require Scalar::Util; goto &Scalar::Util::blessed }

=attr C<sections>

=cut

=method C<sections>

    my $sections = $result->sections;
    for my $key( keys %{$sections}) {
        ...
    }

=cut

has 'sections' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    return {};
  },
);

=p_attr C<_current>

=cut

=method C<set_current>

    $result->set_current('foo');

=method C<has_current>

    if ( $result->has_current ){
    }

=p_method C<_current>

    my $current = $result->_current;

=cut

has '_current' => (
  is        => ro  =>,
  reader    => '_current',
  writer    => 'set_current',
  predicate => 'has_current',
  lazy      => 1,
  builder   => sub { return _croak('current never set, but tried to use it') },
);

has '_section_names' => (
    is => ro =>,
    lazy => 1,
    builder => sub { return [] }
);

=method C<section>

    my $ref = $result->section( $name );
    print ${$ref};

=cut

sub section { return $_[0]->sections->{ $_[1] } }

=method C<section_names>

This contains the names of the sections in the order they were found/inserted.

    my @names = $result->section_names;

=cut

sub section_names { return ( my @list = @{ $_[0]->_section_names } ) }


=method C<section_names_sorted>

=cut

sub section_names_sorted { return ( my @list = sort @{ $_[0]->_section_names } ) }

=method C<has_section>

    if ( $result->has_section($name) ) {
        ...
    }

=cut

sub has_section { return exists $_[0]->sections->{ $_[1] } }

=method C<set_section>

    $result->set_section($name, \$data);

=cut

sub set_section {
    if ( not exists $_[0]->sections->{$_[1]} ) {
        push @{ $_[0]->_section_names }, $_[1];
    }
    $_[0]->sections->{ $_[1] } = $_[2];
    return;
}

=method C<append_data_to_current_section>

    # Unitialise slot
    $result->append_data_to_current_section();
    # Unitialise and/or extend slot
    $result->append_data_to_current_section('somedata');

=cut

sub append_data_to_current_section {
  if ( not exists $_[0]->sections->{ $_[0]->_current } ) {
    push @{ $_[0]->_section_names }, $_[0]->_current;
    my $blank = q{};
    $_[0]->sections->{ $_[0]->_current } = \$blank;
  }
  if ( defined $_[1] ) {
    ${ $_[0]->sections->{ $_[0]->_current } } .= ${ $_[1] };
  }
  return;
}

=method C<append_data_to_section>

    # Unitialise slot
    $result->append_data_to_current_section( $name );
    # Unitialise and/or extend slot
    $result->append_data_to_current_section( $name, 'somedata');

=cut

sub append_data_to_section {
  if ( not exists $_[0]->sections->{ $_[1] } ) {
    push @{ $_[0]->_section_names }, $_[1];
    my $blank = q{};
    $_[0]->sections->{ $_[1] } = \$blank;
  }
  if ( defined $_[2] ) {
    ${ $_[0]->sections->{ $_[1] } } .= ${ $_[2] };
  }
  return;
}

=method C<shallow_clone>

    my $clone = $result->shallow_clone;

    if ( refaddr $clone->section('foo') == refaddr $result->section('foo') ) {
        print "clone success!"
    }

=cut

sub shallow_clone {
  my $class = _blessed( $_[0] ) || $_[0];
  my $instance = $class->new();
  for my $name ( $_[0]->section_names ) {
    $instance->set_section( $name, $_[0]->sections->{$name} );
  }
  return $instance;
}

=method C<shallow_merge>

    my $merged = $result->shallow_merge( $other );

    if ( refaddr $merged->section('foo') == refaddr $result->section('foo') ) {
        print "foo copied from orig successfully!"
    }
    if ( refaddr $merged->section('bar') == refaddr $other->section('bar') ) {
        print "bar copied from other successfully!"
    }

=cut

sub shallow_merge {
  my $class = _blessed( $_[0] ) || $_[0];
  my $instance = $class->new();
  for my $name ( $_[0]->section_names ) {
    $instance->set_section($name,  $_[0]->sections->{$name});
  }
  for my $name ( $_[1]->section_names ) {
    $instance->set_section( $name, $_[1]->sections->{$name});
  }
  return $instance;
}

=p_method C<_compose_section>

    my $str = $result->_compose_section('bar');

=cut

sub _compose_section {
  return sprintf qq[__[%s]__\n%s], $_[1], ${ $_[0]->sections->{ $_[1] } };
}

=method C<to_s>

    my $str = $result->to_s

=cut

sub to_s {
  my $self = $_[0];
  return join qq{\n}, map { $self->_compose_section($_) } sort keys %{ $self->sections };
}

1;
