package MyPan::App::Command::Create;
use Moose;
use Path::Class;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'create an empty repository' }

# args: repo/version
# creates POST /repo/ver
sub run {
    my ($self, $args) = @_;
    
    die 'Add: repository arg needed'
        if scalar @$args != 1;
    
    $self->server->post(shift @$args);
}

__PACKAGE__->meta->make_immutable;
1;
