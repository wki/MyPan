package MyPan::App::Command::Log;
use Modern::Perl;
use Moose;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'show collected log entries' }

# arg: repository
sub run {
    my ($self, $args) = @_;
    
    die 'Log: repository arg needed'
        if scalar @$args != 1;
        
    say $self->server->get(shift(@$args) . '/log/update.log');
}

__PACKAGE__->meta->make_immutable;
1;
