package MyPan::Const;
use Modern::Perl;
use base 'Exporter';

our @EXPORT = qw(
    GLOBAL_DIR UPLOAD_DIR LOG_DIR AUTHOR_DIR AUTHOR_ID_DIR MODULE_DIR
    MAILRC_FILE PACKAGES_FILE MODLIST_FILE REVISIONS_FILE RECENT_FILE
    UPDATELOG_FILE ACCESSLOG_FILE
    CPAN_URL
);

use constant GLOBAL_DIR     => '_GLOBAL';
use constant UPLOAD_DIR     => 'uploads';
use constant LOG_DIR        => 'log';
use constant AUTHOR_DIR     => 'authors';
use constant AUTHOR_ID_DIR  => 'authors/id';
use constant MODULE_DIR     => 'modules';

use constant MAILRC_FILE    => '01mailrc.txt.gz';
use constant PACKAGES_FILE  => '02packages.details.txt.gz';
use constant MODLIST_FILE   => '03modlist.data.gz';
use constant REVISIONS_FILE => 'revisions.txt';
use constant RECENT_FILE    => 'RECENT';
use constant UPDATELOG_FILE => 'update.log';
use constant ACCESSLOG_FILE => 'access.log';

use constant CPAN_URL   => 'http://cpan.noris.net';

1;
