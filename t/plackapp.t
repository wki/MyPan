use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeDistribution;
use File::Temp 'tempdir';
use Path::Class;
use Test::More;
use Test::Exception;

use ok 'MyPan::PlackApp';

my $dir = dir(tempdir(CLEANUP => 1));
my $app = MyPan::PlackApp->new(root => $dir);

my $some_package_003 = FakeDistribution->new(name => 'Some-Package-0.03');
$some_package_003->add_package('Some::Package', '0.01');
$some_package_003->add_package('Some::Package::Xxx', '0.02');

# error handling
{
    lives_ok { my $x = $app->error }
        'error() lives in scalar context';

    dies_ok { my $x; $app->error; my $y; }
        'error() dies in void context';

    is_deeply $app->error,
        [400,
         ['Content-Type' => 'text/plain', 'Content-Length' => 11],
         ['Bad Request'],
        ],
        'error() default values OK';

    is_deeply $app->error(444, 'foo'),
        [444,
         ['Content-Type' => 'text/plain', 'Content-Length' => 3],
         ['foo'],
        ],
        'error() values can get overridden';

    eval { my $x; $app->error; my $y };
    is_deeply $@,
        [400,
         ['Content-Type' => 'text/plain', 'Content-Length' => 11],
         ['Bad Request'],
        ],
        'exception is an ArrayRef';
}

# list empty directory
{
    # use Data::Dumper; warn Dumper $app->handle_get({PATH_INFO => ''});
    is_deeply $app->handle_get({PATH_INFO => ''}),
        [200, ['Content-Type' => 'text/plain'], ['']],
        'nothing returned when listing an empty repository';

    is_deeply $app->handle_get({PATH_INFO => '/'}),
        [200, ['Content-Type' => 'text/plain'], ['']],
        'nothing returned when listing / on an empty repository';

    dies_ok { $app->handle_get({PATH_INFO => '/foo'}) }
        'dies when listing /foo on an empty repository';

    dies_ok { $app->handle_get({PATH_INFO => '/foo/1.0'}) }
        'dies when listing /foo/1.0 on an empty repository';

    is_deeply $app->handle_get({PATH_INFO => '/foo/1.0/authors/id/C/CL/CLEVER/x.tar.gz'}),
        [405,
         ['Content-Type' => 'text/plain', 'Content-Length' => 69],
         ["GET '/foo/1.0/authors/id/C/CL/CLEVER/x.tar.gz' not handled internally"]
        ],
        '405 for too long paths';
}

# creating things
{
    dies_ok { $app->handle_post({PATH_INFO => ''}) }
        'posting nothing dies';

    dies_ok { $app->handle_post({PATH_INFO => 'hrko'}) }
        'posting repository without version nothing dies';

    lives_ok { $app->handle_post({PATH_INFO => 'hrko/1.0'}) }
        'posting a repository with version lives';
    ok -d $dir->subdir('hrko/1.0'), 'repository directory created';

    dies_ok { $app->handle_post({PATH_INFO => 'hrko/1.0'}) }
        'posting an existing repository dies';


    dies_ok { $app->handle_post({PATH_INFO => 'hrko/1.0/WKI/X-1.tar.gz'}) }
        'posting an distribution without upload dies';
    
    ### TODO: how to test a plack upload???
    #   use Plack::Test; test_psgi ...
    # my $upload = Plack::Request::Upload->new(
    #     tempname => $some_package_003->tar_gz_file->stringify,
    #     size     => -s $some_package_003->tar_gz_file,
    #     filename => 'Some-Package-0.03.tar.gz',
    # );
    
}

# list filled directory
{
    my $x;
}


done_testing;
