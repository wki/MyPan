use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeDistribution;
use Path::Class;
use Test::More;

use ok 'MyPan::Packages';

my $some_package_003 = FakeDistribution->new(name => 'Some-Package-0.03');
$some_package_003->add_package('Some::Package', '0.01');
$some_package_003->add_package('Some::Package::Xxx', '0.02');

my $packages = MyPan::Packages->new(
    file => "$FindBin::Bin/data/02packages.details.txt.gz"
);

is_deeply
    $packages->packages_for,
    {
        'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' =>
            [
                { package => 'AAA::Demo', version => 'undef' },
                { package => 'AAA::eBay', version => 'undef' },
            ],
        'J/JO/JOUKE/AAC-Pvoice-0.91.tar.gz' =>
            [
                { package => 'AAC::Pvoice',         version => '0.91' },
                { package => 'AAC::Pvoice::Bitmap', version => '1.12' },
            ],
    },
    'version list is correctly extracted from file';

$packages->add_distribution(
    WXFOO => $some_package_003->tar_gz_file
);

is_deeply
    $packages->packages_for,
    {
        'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' =>
            [
                { package => 'AAA::Demo', version => 'undef' },
                { package => 'AAA::eBay', version => 'undef' },
            ],
        'J/JO/JOUKE/AAC-Pvoice-0.91.tar.gz' =>
            [
                { package => 'AAC::Pvoice',         version => '0.91' },
                { package => 'AAC::Pvoice::Bitmap', version => '1.12' },
            ],
        'W/WX/WXFOO/Some-Package-0.03.tar.gz' =>
            [
                { package => 'Some::Package',      version => '0.01' },
                { package => 'Some::Package::Xxx', version => '0.02' },
            ],
    },
    'version list is correct after adding a distribution';

$packages->save(file('/tmp/xxx.gz'));

my $p2 = MyPan::Packages->new(file => "/tmp/xxx.gz");
is_deeply
    $p2->packages_for,
    {
        'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' =>
            [
                { package => 'AAA::Demo', version => 'undef' },
                { package => 'AAA::eBay', version => 'undef' },
            ],
        'J/JO/JOUKE/AAC-Pvoice-0.91.tar.gz' =>
            [
                { package => 'AAC::Pvoice',         version => '0.91' },
                { package => 'AAC::Pvoice::Bitmap', version => '1.12' },
            ],
        'W/WX/WXFOO/Some-Package-0.03.tar.gz' =>
            [
                { package => 'Some::Package',      version => '0.01' },
                { package => 'Some::Package::Xxx', version => '0.02' },
            ],
    },
    'version list from saved file is equal to expected list';

$p2->remove_distribution(
    WXFOO => $some_package_003->tar_gz_file
);

is_deeply
    $p2->packages_for,
    {
        'J/JW/JWACH/Apache-FastForward-1.1.tar.gz' =>
            [
                { package => 'AAA::Demo', version => 'undef' },
                { package => 'AAA::eBay', version => 'undef' },
            ],
        'J/JO/JOUKE/AAC-Pvoice-0.91.tar.gz' =>
            [
                { package => 'AAC::Pvoice',         version => '0.91' },
                { package => 'AAC::Pvoice::Bitmap', version => '1.12' },
            ],
    },
    'version list shrinks after deletion';

done_testing;
