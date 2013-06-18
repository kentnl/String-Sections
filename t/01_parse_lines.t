#
#===============================================================================

use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;

my $e;

is(
  $e = exception {
    require String::Sections;
  },
  undef,
  "Can require String::Sections"
) or diag explain $e;

my $sections;
my $checkstash = {};
is(
  $e = exception {

    $sections = String::Sections->new();

    $sections->load_list( "__[ Foo ]__\n", "line\n" );

    my @section_names = $sections->section_names();

    for my $section_name (@section_names) {

      # yes, this is redundant, just testing behaviour.
      if ( $sections->has_section($section_name) ) {
        my $ref = $sections->section($section_name);
        $checkstash->{$section_name} = ${$ref};
      }
    }

  },
  undef,
  "Basic Syntax works"
) or diag explain $e;

is_deeply( [ $sections->section_names ], [ 'Foo' ], 'Section names parsed out correctly');
is_deeply( $checkstash, { Foo => "line\n" }, 'Section data extracted correctly');
done_testing();
