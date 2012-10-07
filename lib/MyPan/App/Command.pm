package MyPan::App::Command;
use Modern::Perl;
use Moose;
use namespace::autoclean;

sub run {
    my $self = shift;
    
    my $command = lc ref $self;
    $command =~ s{\A .* ::}{}xms;
    
    say "Command '$command' not implemented...";
}

sub description { 'no description defined yet' }

__PACKAGE__->meta->make_immutable;
1;
