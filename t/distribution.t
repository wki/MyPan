use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeDistribution;
use Test::More;

use ok 'MyPan::Distribution';

my $some_package_003 = FakeDistribution->new(name => 'Some-Package-0.03');
$some_package_003->add_package('Some::Package', '0.01');
$some_package_003->add_package('Some::Package::Xxx', '0.02');

my $dist = MyPan::Distribution->new(
    author => 'WXFOO',
    file   => $some_package_003->tar_gz_file,
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
