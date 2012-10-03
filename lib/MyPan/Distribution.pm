package MyPan::Distribution;
use Moo;
use Dist::Data;
use MyPan::Types;

has author => (
    is => 'ro',
    required => 1,
);

has file => (
    is => 'ro',
    coerce => to_File,
    required => 1,
);

sub author_distribution_path {
    join '/', ($_->[0]->dir_list)[-4 .. -1]
}

sub get_packages {
    my $self = shift;

    my $dist = Dist::Data->new($self->file);

    map {
        [
            $_,
            $dist->packages->{$_}->{version},
            $self->author_distribution_path
        ]
    }
    keys %{$dist->packages};
}

1;
