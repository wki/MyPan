package MyPan::Repository;
use Moo;
use MyPan::Types;
# use CPAN::Repository;

with 'MyPan::Role::HTTP';

has root => (
    is       => 'ro',
    required => 1,
    coerce   => to_Dir,
);

has repository => (
    is => 'lazy',
);

sub _build_repository { CPAN::Repository->new({ dir => $_[0]->root }) }

sub exists { -d $_[0]->root }

sub create {
    my $self = shift;

    warn 'repository :: create';

    if (!$self->exists) {
        $self->root->mkpath;
        
        # $self->repository->initialize if !$self->repository->is_initialized;
        
        ### TODO: make a directory for keeping uploads
        ### TODO: init log
    }
}

sub global_dir { $_[0]->root->subdir('GLOBAL') }

sub update_global_files {
    my $self = shift;
    
    $self->global_dir->mkpath if !-d $self->global_dir;
    
    # my $mail_txt = 
    $self->global_dir
         ->file('01mail.txt.gz')
         ->spew(...)
}

sub add_distribution {
    my ($self, $destination_path, $source_file) = @_;
    
    warn 'repository :: add_distribution';
}

sub remove_distribution {
    my ($self, $destination_path) = @_;
}

sub log {
    my ($self, $message) = @_;
}

1;
