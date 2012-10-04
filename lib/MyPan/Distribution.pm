package MyPan::Distribution;
use Moo;
use Dist::Data;
use MyPan::Types;

has author => (
    is => 'lazy',
);

sub _build_author {
    my $self = shift;
    
    my $author = $self->file->dir->basename;
    
    die "cannot guess author from file: '${\$self->file}'"
        if $author eq '.';
    
    return $author;
}

has file => (
    is => 'ro',
    coerce => to_File,
    required => 1,
);

sub author_distribution_path {
    my $self = shift;
    
    join '/',
        substr($self->author, 0, 1),
        substr($self->author, 0, 2),
        $self->author,
        $self->file->basename;
}

sub packages {
    my $self = shift;

    my $dist = Dist::Data->new($self->file);

    [
        sort { $a->{package} cmp $b->{package} }
        map {
            {
                package => $_,
                version => $dist->packages->{$_}->{version} // 'undef',
            }
        }
        keys %{$dist->packages}
    ];
}

1;
