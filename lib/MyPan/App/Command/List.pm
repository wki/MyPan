package MyPan::App::Command::List;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'list repositories, versions or packages' }


__PACKAGE__->meta->make_immutable;
1;
