package MyPan::Revisions;
use Modern::Perl;
use Moose;
use MooseX::Types::Path::Class qw(File);
use Try::Tiny;
use namespace::autoclean;

has file => (
    is          => 'ro',
    isa         => File,
    coerce      => 1,
    required    => 1,
);

has revision_info => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy_build  => 1,
    clearer     => 'clear_revision_info',
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

__PACKAGE__->meta->make_immutable;
1;
