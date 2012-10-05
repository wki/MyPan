use strict;
use warnings;
use FindBin;
use File::Temp 'tempdir';
use Path::Class;
use Test::More;

use ok 'MyPan::Revisions';

my $dir = dir(tempdir(CLEANUP => 1));
my $file = $dir->file('revisions.txt');

my $revisions = MyPan::Revisions->new(file => $file);

#
# empty revisions file
#
is_deeply $revisions->revision_info, [],
    'initially revisions are empty';

is $revisions->current_revision, 0, 'initially current revision is 0';
is $revisions->next_revision,    1, 'initially next revision is 1';

#
# add a revision
#
$revisions->add(qw(+ WKI Some-Thing-0.01.tar.gz));
is_deeply $revisions->revision_info,
    [
        { revision => 1, operation => '+', author => 'WKI', file => 'Some-Thing-0.01.tar.gz' },
    ],
    'one revision in file';

is $revisions->current_revision, 1, 'current revision is 1';
is $revisions->next_revision,    2, 'next revision is 2';

#
# re-read changed file
#
$file->spew(<<EOF);
00001 + WKI Another-Thing-2.0.tar.gz
00002 - STUPID Nothing-1.0.tar.gz
00003 > 00001
EOF
$revisions->clear_revision_info;

is_deeply $revisions->revision_info,
    [
        { revision => 1, operation => '+', author => 'WKI',    file => 'Another-Thing-2.0.tar.gz' },
        { revision => 2, operation => '-', author => 'STUPID', file => 'Nothing-1.0.tar.gz' },
        { revision => 3, operation => '>', revert_to => 1 },
    ],
    'three revisions in file';

is $revisions->current_revision, 3, 'current revision is 3';
is $revisions->next_revision,    4, 'next revision is 4';


done_testing;
