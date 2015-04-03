use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/String/Sections.pm',
    'lib/String/Sections/Result.pm',
    't/00-compile/lib_String_Sections_Result_pm.t',
    't/00-compile/lib_String_Sections_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-String-Sections-Result/basic.t',
    't/01_parse_lines.t',
    't/02-String-Sections/parse_filehandles/empty.t',
    't/02-String-Sections/parse_filehandles/nosections.t',
    't/02-String-Sections/parse_filehandles/onesection_full.t',
    't/02-String-Sections/parse_filehandles/onesection_head.t',
    't/02-String-Sections/parse_filehandles/prelude.t',
    't/02-String-Sections/parse_filehandles/twosection_full.t',
    't/02-String-Sections/parse_filehandles/twosection_secondhead.t',
    't/02-String-Sections/parse_list/empty.t',
    't/02-String-Sections/parse_list/nosections.t',
    't/02-String-Sections/parse_list/onesection_full.t',
    't/02-String-Sections/parse_list/onesection_head.t',
    't/02-String-Sections/parse_list/prelude.t',
    't/02-String-Sections/parse_list/twosection_full.t',
    't/02-String-Sections/parse_list/twosection_secondhead.t',
    't/lib/Test/Fatal/Assert.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
