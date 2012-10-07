package MyPan::App::Command::Log;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'show collected log entries' }

__PACKAGE__->meta->make_immutable;
1;
