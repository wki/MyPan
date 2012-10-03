package MyPan::Packages;
use Moo;
use MyPan::Types;

has file => (
    is => 'ro',
    coerce => to_File,
    required => 1,
);

has distributions => (
    is => 'rw',
    default => sub { [] },
);

sub BUILD {
    my $self = shift;
    
    # load file, extract distributions
}

sub add_distribution {
    
}

sub remove_distribution {
    
}

sub save {
    
}

1;
