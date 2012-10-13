package MyPan::App::Command::Revisions;
use Modern::Perl;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'show revision entries' }

# arg: repository
sub run {
    my ($self, $args) = @_;
    
    die 'Revisions: repository arg needed'
        if scalar @$args != 1;
        
    say $self->server->get(shift(@$args) . '/log/revisions.txt');
}

__PACKAGE__->meta->make_immutable;
1;
