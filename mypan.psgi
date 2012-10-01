use Plack::Builder;
use Plack::App::Cascade;
use Plack::App::File;
use MyPan::PlackApp;

# to create a demo repo, execute:
# perl -MCPAN::Repository -e '$r=CPAN::Repository->new({dir=>"/Users/wolfgang/tmp/myrepo", url=>"http://asdf"}); $r->initialize unless $r->is_initialized; $r->add_author_distribution("WKI", "/Users/wolfgang/proj/Catalyst-Controller-Combine/Catalyst-Controller-Combine-0.14.tar.gz");'

my $ROOT_DIR = '/Users/wolfgang/tmp/myrepo';

my $file_app = Plack::App::File->new(root => $ROOT_DIR)->to_app;
my $pan_app  = MyPan::PlackApp ->new(root => $ROOT_DIR)->to_app;

my $cascade  = Plack::App::Cascade->new;
$cascade->catch([405]); # 405 = Method not allowed
$cascade->add($pan_app);
$cascade->add($file_app);

my $cascade_app = $cascade->to_app;

builder {
    $cascade_app;
};
