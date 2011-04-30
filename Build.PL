
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Test::Fatal' => '0',
    'Test::More' => '0.96'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Extract labelled groups of sub-strings from a string.',
  'dist_author' => [
    'Kent Fredric <kentnl@cpan.org>'
  ],
  'dist_name' => 'String-Sections',
  'dist_version' => '0.1.0',
  'license' => 'perl',
  'module_name' => 'String::Sections',
  'recommends' => {
    'Params::Classify' => '0'
  },
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Package::Stash' => '0',
    'Scalar::Util' => '0',
    'perl' => '5.010001'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
