#!/usr/bin/env perl
use Plack::Builder;
use Plack::App::Cascade;
use Plack::App::File;
use MyPan::PlackApp;

# directory must exist prior to starting the plack app.
my $ROOT_DIR = '/Users/wolfgang/tmp/myrepo';
die "Root directory '$ROOT_DIR' does not exist"
    if !-d $ROOT_DIR;

#
# simple authentication
#
sub authenticate {
    my ($username, $password) = @_;
    
    return $username eq 'wolfgang' && $password eq 'secret';
}

#
# the pan_app allows querying and manipulating repositories
#
my $pan_app = builder {
    enable 'Auth::Basic', authenticator => \&authenticate;
    MyPan::PlackApp->new(root => $ROOT_DIR)->to_app;
};

#
# the file_app allows unauthenticated CPAN clients to work
#
my $file_app = Plack::App::File->new(root => $ROOT_DIR)->to_app;

#
# the cascade merges both apps above
#   * try to serve static files unauthenticated first
#   * then switch to MyPan app with authentication
#

my $cascade = Plack::App::Cascade->new;
$cascade->catch([404]); # 404 = Not found
$cascade->add($file_app);
$cascade->add($pan_app);

my $cascade_app = $cascade->to_app;

#
# build a total app. Allow more middleware to get added
#
builder {
    # enable 'More::Middleware', arg => 'foo';
    $cascade_app;
};
