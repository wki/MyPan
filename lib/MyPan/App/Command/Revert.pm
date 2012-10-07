package MyPan::App::Command::Revert;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'revert the repository to a given state' }

__PACKAGE__->meta->make_immutable;
1;
