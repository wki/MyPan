use strict;
use warnings;
use File::Temp 'tempdir';
use Path::Class;
use Test::More;
use Test::Exception;

use ok 'MyPan::PlackApp';

my $dir = dir(tempdir(CLEANUP => 1));
my $app = MyPan::PlackApp->new(root => $dir);

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

done_testing;
