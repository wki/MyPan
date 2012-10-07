package MyPan::App::Command::Add;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'add a distribution to a repository' }

__PACKAGE__->meta->make_immutable;
1;
