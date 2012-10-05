package MyPan::Revisions;
use feature ':5.10';
use Moo;
use MyPan::Types;
use Try::Tiny;

has file => (
    is => 'ro',
    coerce => to_File,
    required => 1,
);

has revision_info => (
    is => 'lazy',
    clearer => 1,
);

sub _build_revision_info {
    my $self = shift;

    my @revisions;

    try {
        @revisions =
            map {
                m{\A 0* (\d+) \s+ ([+-]) \s+ ([A-Z]+) \s+ (.*?) \s* \z}xms
                    ? {
                        revision  => $1,
                        operation => $2,
                        author    => $3,
                        file      => $4 }
              : m{\A 0* (\d+) \s+ (>) \s+ 0* (\d+) \s* \z}xms
                    ? {
                        revision  => $1,
                        operation => $2,
                        revert_to => $3
                    }
              : ()
            }
            $self->file->slurp;
    };

    return \@revisions;
}

sub current_revision {
    my $self = shift;

    scalar @{$self->revision_info}
        ? $self->revision_info->[-1]->{revision}
        : 0;
}

sub next_revision { $_[0]->current_revision + 1 }

sub add {
    my $self = shift;

    my $fh = $self->file->open('>>');
    say $fh join ' ', sprintf('%05d', $self->next_revision), @_;
    $fh->close;

    $self->clear_revision_info;
}

1;
