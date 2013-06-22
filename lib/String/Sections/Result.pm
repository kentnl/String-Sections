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

use Moo;

## no critic (RequireArgUnpacking)

sub _croak   { require Carp;         goto &Carp::croak; }
sub _blessed { require Scalar::Util; goto &Scalar::Util::blessed }

=attr sections

=cut

=method sections

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

=p_attr _current

=cut

=method set_current

    $result->set_current('foo');

=method has_current

    if ( $result->has_current ){
    }

=p_method _current

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

=method section

    my $ref = $result->section( $name );
    print ${$ref};

=cut

sub section { return $_[0]->sections->{ $_[1] } }

=method section_names

    my @names = $result->section_names;

=cut

sub section_names { return ( my @list = sort keys %{ $_[0]->sections } ) }

=method has_section

    if ( $result->has_section($name) ) {
        ...
    }

=cut

sub has_section { return exists $_[0]->sections->{ $_[1] } }

=method set_section

    $result->set_section($name, \$data);

=cut

sub set_section { $_[0]->sections->{ $_[1] } = $_[2]; return; }

=method append_data_to_current_section

    # Unitialise slot
    $result->append_data_to_current_section();
    # Unitialise and/or extend slot
    $result->append_data_to_current_section('somedata');

=cut

sub append_data_to_current_section {
  if ( not exists $_[0]->sections->{ $_[0]->_current } ) {
    my $blank = q{};
    $_[0]->sections->{ $_[0]->_current } = \$blank;
  }
  if ( defined $_[1] ) {
    ${ $_[0]->sections->{ $_[0]->_current } } .= ${ $_[1] };
  }
  return;
}

=method append_data_to_section

    # Unitialise slot
    $result->append_data_to_current_section( $name );
    # Unitialise and/or extend slot
    $result->append_data_to_current_section( $name, 'somedata');

=cut

sub append_data_to_section {
  if ( not exists $_[0]->sections->{ $_[1] } ) {
    my $blank = q{};
    $_[0]->sections->{ $_[1] } = \$blank;
  }
  if ( defined $_[2] ) {
    ${ $_[0]->sections->{ $_[1] } } .= ${ $_[2] };
  }
  return;
}

=method shallow_clone

    my $clone = $result->shallow_clone;

    if ( refaddr $clone->section('foo') == refaddr $result->section('foo') ) {
        print "clone success!"
    }

=cut

sub shallow_clone {
  my $class = _blessed( $_[0] ) || $_[0];
  my $instance = $class->new();
  for my $name ( keys %{ $_[0]->sections } ) {
    $instance->sections->{$name} = $_[0]->sections->{$name};
  }
  return $instance;
}

=method shallow_merge

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
  for my $name ( keys %{ $_[0]->sections } ) {
    $instance->sections->{$name} = $_[0]->sections->{$name};
  }
  for my $name ( keys %{ $_[1]->sections } ) {
    $instance->sections->{$name} = $_[1]->sections->{$name};
  }
  return $instance;
}

=p_method _compose_section

    my $str = $result->_compose_section('bar');

=cut

sub _compose_section {
  return sprintf qq[__[%s]__\n%s], $_[1], ${ $_[0]->sections->{ $_[1] } };
}

=method to_s

    my $str = $result->to_s

=cut

sub to_s {
  my $self = $_[0];
  return join qq{\n}, map { $self->_compose_section($_) } sort keys %{ $self->sections };
}

1;
