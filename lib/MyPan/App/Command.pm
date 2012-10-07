package MyPan::App::Command;
use Modern::Perl;
use Moose;
use MyPan::App::MyPan;
use MyPan::App::Server;
use namespace::autoclean;

sub run {
    my $self = shift;
    
    my $command = lc ref $self;
    $command =~ s{\A .* ::}{}xms;
    
    say "Command '$command' not implemented...";
}

has server => (
    is => 'ro',
    # isa => 'MyPan::App::Server',
    lazy_build => 1,
);

sub _build_server {
    MyPan::App::Server->new(host => MyPan::App::MyPan->instance->server);
}

sub description { 'no description defined yet' }

__PACKAGE__->meta->make_immutable;
1;
