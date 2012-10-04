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
    is => 'rw',
    default => sub { [] },
    clearer => 1,
);

sub BUILD {
    my $self = shift;

    try {
        my @revisions =
            map {
                m{\A 0* (\d+) \s+ ([+-]) \s+ ([A-Z]+) \s+ (.*) \z}xms
                    ? {
                        revision  => $1,
                        operation => $2,
                        author    => $3,
                        file      => $4 }
              : m{\A 0* (\d+) \s+ (>) \s+ 0* (\d+) \z}xms
                    ? {
                        revision  => $1,
                        operation => $2,
                        revert_to => $3
                    }
              : ()
            }
            $self->file->slurp(chomp => 1);
        
        $self->revision_info(\@revisions);
    };
}

sub current_revision {
    my $self = shift;

    # use Data::Dumper; warn Dumper $self->revision_info;
    
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
