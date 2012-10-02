package MyPan::Repository;
use Moo;
use MyPan::Types;
use CPAN::Repository;

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
        $self->repository->initialize if !$self->repository->is_initialized;
        
        ### TODO: make a directory for keeping uploads
        ### TODO: init log
    }
}

sub save_file {
    my ($self, $path, $content) = @_;
    
    warn 'repository :: save file';
}



1;

__END__

$r=CPAN::Repository->new({dir=>"/Users/wolfgang/tmp/myrepo", url=>"http://asdf"});
$r->initialize unless $r->is_initialized;
$r->add_author_distribution("WKI", "/Users/wolfgang/proj/Catalyst-Controller-Combine/Catalyst-Controller-Combine-0.14.tar.gz");

