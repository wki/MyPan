#!/usr/bin/env perl
use Plack::Builder;
use Plack::App::Cascade;
use Plack::App::File;
use MyPan::PlackApp;

# directory must exist prior to starting the plack app.
my $ROOT_DIR = '/Users/wolfgang/tmp/myrepo';
die "Root directory '$ROOT_DIR' does not exist"
    if !-d $ROOT_DIR;

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
