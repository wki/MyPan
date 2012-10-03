use strict;
use warnings;
use FindBin;
use Path::Class;
use Test::More;

use ok 'MyPan::Packages';

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
    WXFOO => file($FindBin::Bin, 'data/Some-Package-0.03.tar.gz')
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

$packages->save(file($FindBin::Bin, 'data/xxx.gz'));

my $p2 = MyPan::Packages->new(file => "$FindBin::Bin/data/xxx.gz");
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
    WXFOO => file($FindBin::Bin, 'data/Some-Package-0.03.tar.gz')
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
