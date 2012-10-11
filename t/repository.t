use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeDistribution;
use File::Temp 'tempdir';
use Path::Class;
use Test::More;

use ok 'MyPan::Repository';

my $some_package_003 = FakeDistribution->new(name => 'Some-Package-0.03');
$some_package_003->add_package('Some::Package', '0.01');
$some_package_003->add_package('Some::Package::Xxx', '0.02');

my $some_package_100 = FakeDistribution->new(name => 'Some-Package-1.00');
$some_package_100->add_package('Some::Package', '0.02');
$some_package_100->add_package('Some::Package::Xxx', '0.03');

my $another_module_207 = FakeDistribution->new(name => 'Another-Module-2.07');
$another_module_207->add_package('Another::Module', '0.03');
$another_module_207->add_package('Another::Module::Foo', '2.02');



my $dir = dir(tempdir(CLEANUP => 1));
my $repository = MyPan::Repository->new(root => $dir, name => 'foobar/1.0');

# initial condition
{
 ok !-d $repository->dir, 'repository directory is not present';
 ok !$repository->exists, 'initially a repository does not exist';
 is scalar $dir->children, 0, 'root directory is empty before create';
}

# creation of a repository
my $repo_dir;
{
    $repository->create;
    
    foreach my $f (qw(01mailrc.txt.gz 03modlist.data.gz RECENT)) {
        ok -f "$dir/_GLOBAL/$f", "file '$f' exists in GLOBAL";
        ok -s "$dir/_GLOBAL/$f", "file '$f' has nonzero size";
    }
    
    ok -d $repository->dir, 'repository directory is present after creation';
    ok $repository->exists, 'repository is reported as existing after creation';
    
    $repo_dir = $dir->subdir('foobar/1.0');
    
    foreach my $d (qw(uploads log authors modules)) {
        ok -d $repo_dir->subdir($d), "dir '$d' exists in repository";
    }
    
    foreach my $f (qw(authors/01mailrc.txt.gz modules/03modlist.data.gz RECENT)) {
        my $basename = file($f)->basename;
        is $dir->file("_GLOBAL/$basename")->stat->ino,
           $repo_dir->file($f)->stat->ino,
           "file '$f' is hard-linked to Global";
    }
    
    foreach my $d (qw(uploads log)) {
        is scalar $repo_dir->subdir($d)->children, 0, "dir '$d' is empty";
    }
}

# uploading a distribution
{
    $repository->add_distribution(
        'STUPID/Some-Package-0.03.tar.gz',
        $some_package_003->tar_gz_file
    );
    
    ok -f $repo_dir->file('uploads/000/00001-STUPID-Some-Package-0.03.tar.gz'),
        'uploaded file exists in upload dir';
    ok -f $repo_dir->file('log/revisions.txt'),
        'revision file exists in log dir';
    ok -f $repo_dir->file('modules/02packages.details.txt.gz'),
        'packages file exists in modules dir';
    
    is scalar $repository->revision_file->slurp,
        "00001 + STUPID Some-Package-0.03.tar.gz\n",
        'revision file content looks good';
    
    ok -f $repo_dir->file('authors/id/S/ST/STUPID/Some-Package-0.03.tar.gz'),
        'uploaded file exists in authors dir';
    
    is $repo_dir->file('uploads/000/00001-STUPID-Some-Package-0.03.tar.gz')->stat->ino,
        $repo_dir->file('authors/id/S/ST/STUPID/Some-Package-0.03.tar.gz')->stat->ino,
        'file in authors dir is hard-linked to uploaded file';
    
    isa_ok $repository->revisions, 'MyPan::Revisions';
    
    is_deeply $repository->revisions->revision_info,
        [
            { revision => 1, operation => '+', author => 'STUPID', file => 'Some-Package-0.03.tar.gz' },
        ],
        'revision_info reflects upload 1';
    
    is join('|', sort keys %{$repository->packages->packages_for}),
        'S/ST/STUPID/Some-Package-0.03.tar.gz',
        'only one package registered';
}


# uploading another distribution
{
    $repository->add_distribution(
        'CLEVER/Another-Module-2.07.tar.gz',
        $another_module_207->tar_gz_file
    );
    
    ok -f $repo_dir->file('uploads/000/00002-CLEVER-Another-Module-2.07.tar.gz'),
        'uploaded file 2 exists in upload dir';
    
    is_deeply $repository->revisions->revision_info,
        [
            { revision => 1, operation => '+', author => 'STUPID', file => 'Some-Package-0.03.tar.gz' },
            { revision => 2, operation => '+', author => 'CLEVER', file => 'Another-Module-2.07.tar.gz' },
        ],
        'revision_info reflects upload 1';
    
    is join('|', sort keys %{$repository->packages->packages_for}),
        'C/CL/CLEVER/Another-Module-2.07.tar.gz|S/ST/STUPID/Some-Package-0.03.tar.gz',
        'two packages registered';
}


# uploading a similar distribution replaces formerly installed distribution
{
    $repository->add_distribution(
        'SMART/Some-Package-1.0.tar.gz',
        $some_package_100->tar_gz_file
    );
    
    ok -f $repo_dir->file('uploads/000/00003-SMART-Some-Package-1.0.tar.gz'),
        'uploaded file 3 exists in upload dir';
    
    is_deeply $repository->revisions->revision_info,
        [
            { revision => 1, operation => '+', author => 'STUPID', file => 'Some-Package-0.03.tar.gz' },
            { revision => 2, operation => '+', author => 'CLEVER', file => 'Another-Module-2.07.tar.gz' },
            { revision => 3, operation => '+', author => 'SMART',  file => 'Some-Package-1.0.tar.gz' },
        ],
        'revision_info reflects upload 2';
    
    is join('|', sort keys %{$repository->packages->packages_for}),
        'C/CL/CLEVER/Another-Module-2.07.tar.gz|S/SM/SMART/Some-Package-1.0.tar.gz',
        'two packages registered';
}


done_testing;