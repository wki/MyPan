package MyPan::App::Command::List;
use Modern::Perl;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'list repositories, versions or packages' }

sub run {
    my ($self, $args) = @_;
    
    ### FIXME: must be a bit cleverer. best would be to improve intelligence
    ###        on the server.
    say $self->server->get(shift @$args // ());
}

__PACKAGE__->meta->make_immutable;
1;
