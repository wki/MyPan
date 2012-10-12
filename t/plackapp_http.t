use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeDistribution;
use File::Temp 'tempdir';
use Path::Class;
use HTTP::Request::Common qw(GET POST DELETE);
use MyPan::Repository; # for overloading _http_get
use DateTime; # for overloading now
use Test::More;
use Test::Exception;
use Plack::Test;

use ok 'MyPan::PlackApp';

my $dir = dir(tempdir(CLEANUP => 1));
my $app = MyPan::PlackApp->new(root => $dir);

my $some_package_003 = FakeDistribution->new(name => 'Some-Package-0.03');
$some_package_003->add_package('Some::Package', '0.01');
$some_package_003->add_package('Some::Package::Xxx', '0.02');

my @testcases = (
    # empty repository
    (
        {
            name => 'GET ""',
            req  => [GET => 'http://localhost'],
            code => 200,
            content => '',
        },
        {
            name => 'GET /',
            req  => [GET => 'http://localhost/'],
            code => 200,
            content => '',
        },
        {
            name => 'GET /foo',
            req  => [GET => 'http://localhost/foo'],
            code => 400,
            content => "Directory 'foo' does not exist",
        },
        {
            name => 'GET /foo/1.0',
            req  => [GET => 'http://localhost/foo/1.0'],
            code => 400,
            content => "Repository 'foo/1.0' does not exist",
        },
        {
            name => 'GET /foo/1.0/authors/id/C/CL/CLEVER/x.tar.gz url',
            req  => [GET => 'http://localhost/foo/1.0/authors/id/C/CL/CLEVER/x.tar.gz'],
            code => 405,
            content => "GET '/foo/1.0/authors/id/C/CL/CLEVER/x.tar.gz' not handled internally",
        },
    ),

    # create things
    (
        {
            name => 'POST ""',
            req  => [POST => 'http://localhost'],
            code => 400,
            content => 'Repository name required',
        },
        {
            name => 'POST /hrko',
            req  => [POST => 'http://localhost/hrko'],
            code => 400,
            content => 'Repository name required',
        },
        {
            name => 'POST /hrko/1.0',
            req  => [POST => 'http://localhost/hrko/1.0'],
            code => 200,
            content => "Repository 'hrko/1.0' created",
        },
        {
            name => 'GET /hrko/1.0',
            req  => [GET => 'http://localhost/hrko/1.0'],
            code => 200,
            content => '',
        },
        {
            name => 'POST /hrko/1.0 (again)',
            req  => [POST => 'http://localhost/hrko/1.0'],
            code => 400,
            content => "Cannot create 'hrko/1.0': already there",
        },
        {
            name => 'POST /hrko/1.0/WKI/X-1.tar.gz',
            req  => [POST => 'http://localhost/hrko/1.0/WKI/X-1.tar.gz'],
            code => 400,
            content => "upload 'file' required",
        },
        {
            name => 'POST /hrko/1.0/WKI/X-1.tar.gz',
            req  => [
                        POST => 'http://localhost/hrko/1.0/WKI/Some-Package-0.03.tar.gz',
                        Content_Type => 'form-data',
                        Content => [
                            file => [$some_package_003->tar_gz_file->stringify] 
                        ],
                    ],
            code => 200,
            content => "File 'WKI/Some-Package-0.03.tar.gz' uploaded to 'hrko/1.0'",
        },
        {
            name => 'GET /hrko/1.0',
            req  => [GET => 'http://localhost/hrko/1.0'],
            code => 200,
            content => 'WKI/Some-Package-0.03.tar.gz',
        },
        
        {
            name => 'GET /hrko/1.0/log/update.log',
            req  => [GET => 'http://localhost/hrko/1.0/log/update.log'],
            code => 200,
            content => 
                "2011-01-28 15:20:23 (unknown) created repository\n".
                "2011-01-28 15:20:23 (unknown) uploaded 'WKI/Some-Package-0.03.tar.gz'\n"
        },
        
    ),
    
    # delete things
    (
        {
            name => 'DELETE /',
            req  => [DELETE => 'http://localhost/'],
            code => 400,
            content => 'Repository name required',
        },
        {
            name => 'DELETE /hrko/2.3',
            req  => [DELETE => 'http://localhost/hrko/2.3'],
            code => 400,
            content => "Repository 'hrko/2.3' does not exist",
        },
        
        ### TODO: add more delete tests 
        ###       (requires addition of at least 2 more packages)
        ### revert revision
        ### delete package
        ### delete repository
    ),
);


no strict 'refs';
no warnings 'redefine';
local *MyPan::Repository::_http_get = sub { 'foo' };
my $dt = DateTime->new(
    year       => 2011, month      =>  1, day        => 28,
    hour       => 15,   minute     => 20, second     => 23,
    time_zone  => 'local',
);
local *DateTime::now = sub { return $dt->clone };

use strict 'refs';

foreach my $testcase (@testcases) {
    my $name = $testcase->{name};

    test_psgi
        app => $app->to_app,
        client => sub {
            no strict 'refs';
            
            my $cb = shift;
            my ($method, @args) = @{$testcase->{req}};
            my $req = &{$method}(@args);
            my $res = $cb->($req);
            is $res->code, $testcase->{code},
                "$name: code is $testcase->{code}";
            is $res->content, $testcase->{content},
                "$name: content is '$testcase->{content}'";
        };
}

done_testing;
