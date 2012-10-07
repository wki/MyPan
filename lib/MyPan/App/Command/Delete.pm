package MyPan::App::Command::Delete;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'delete a distribution from a repository' }

__PACKAGE__->meta->make_immutable;
1;
