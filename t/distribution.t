use strict;
use warnings;
use FindBin;
use Test::More;

use ok 'MyPan::Distribution';

my $dist = MyPan::Distribution->new(
    author => 'WXFOO',
    file   => "$FindBin::Bin/data/Some-Package-0.03.tar.gz",
);

is $dist->author_distribution_path, 'W/WX/WXFOO/Some-Package-0.03.tar.gz',
    'author_distribution_path is OK';

is_deeply 
    $dist->packages,
    [
        { package => 'Some::Package',      version => '0.01' },
        { package => 'Some::Package::Xxx', version => '0.02' },
    ],
    'package list OK';

done_testing;