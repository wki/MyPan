package MyPan::Repository;
use Moose;
use MooseX::Types::Path::Class qw(Dir);
use Try::Tiny;
use Path::Class;
use LWP::Simple;
use MyPan::Packages;
use MyPan::Revisions;
use MyPan::Const;
use namespace::autoclean;

has root => (
    is          => 'ro',
    isa         => Dir,
    required    => 1,
    coerce      => 1,
);

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has dir => (
    is          => 'ro',
    isa         => Dir,
    lazy_build  => 1,
);

sub _build_dir { $_[0]->root->subdir($_[0]->name) }

has packages => (
    is          => 'ro',
    isa         => 'MyPan::Packages',
    lazy_build  => 1,
    handles     => [ qw() ],
    # clearer     => '_clear_packages',
);

sub _build_packages {
    MyPan::Packages->new(
        file => $_[0]->dir->subdir(MODULE_DIR)->file(PACKAGES_FILE),
    );
}

sub revision_file { $_[0]->dir->file('log/revisions.txt') }

has revisions => (
    is          => 'ro',
    isa         => 'MyPan::Revisions',
    lazy_build  => 1,
    # clearer     => '_clear_revisions',
);

sub _build_revisions {
    MyPan::Revisions->new(
        file => $_[0]->dir->subdir(LOG_DIR)->file(REVISIONS_FILE),
    );
}

sub exists { -d $_[0]->dir }

sub create {
    my $self = shift;

    # warn "create repository ${\$self->name}";

    if (!$self->exists) {
        $self->root->mkpath;
        $self->update_global_files;
        $self->dir->mkpath;
        $self->dir->subdir($_)->mkpath
            for (UPLOAD_DIR, LOG_DIR, AUTHOR_DIR, MODULE_DIR);

        link $self->global_dir->file(RECENT_FILE)
            => $self->dir->file(RECENT_FILE);
        link $self->global_dir->file(MAILRC_FILE)
            => $self->dir->subdir(AUTHOR_DIR)->file(MAILRC_FILE);
        link $self->global_dir->file(MODLIST_FILE)
            => $self->dir->subdir(MODULE_DIR)->file(MODLIST_FILE);
    }
}

sub global_dir { $_[0]->root->subdir(GLOBAL_DIR) }

sub update_global_files {
    my $self = shift;

    $self->global_dir->mkpath if !-d $self->global_dir;

    my @global_files = (
        { name => MAILRC_FILE,  url_path => 'authors' },
        { name => MODLIST_FILE, url_path => 'modules' },
        { name => RECENT_FILE,  url_path => undef },
    );

    foreach my $global_file (@global_files) {
        my $file = $self->global_dir->file($global_file->{name});
        if (!-f $file || $file->stat->mtime < time - 86400) {
            my $url =
                join '/',
                     CPAN_URL,
                     $global_file->{url_path} // (),
                     $global_file->{name};

            my $content = get($url);
            $file->spew($content) if $content;
        }
    }
}

sub add_distribution {
    my ($self, $destination_path, $source_file) = @_;
    
    my ($author, $filename) = $self->_split_path($destination_path);
    
    my $upload_file =
        $self->dir->file(
            $self->_calculate_upload_path(
                $author, $filename, $self->revisions->next_revision
            )
        );
    
    $upload_file->dir->mkpath if !-d $upload_file->dir;
    $upload_file->spew(scalar file($source_file)->slurp);
    
    my $distribution_file =
        $self->_calculate_distribution_file(
            $author, $filename
        );
    
    $distribution_file->dir->mkpath if !-d $distribution_file->dir;
    link $upload_file => $distribution_file;
    
    $self->_remove_distribution_file($self->dir->file(AUTHOR_DIR, 'id', $_))
        for $self->packages->similar_distributions($distribution_file);
    
    $self->packages->add_distribution($author, $distribution_file);
    $self->packages->save;
    
    $self->revisions->add('+', $author, $filename);
}

# path ==> (author, filename)
sub _split_path {
    my ($self, $path) = @_;
    
    my @parts = split '/', $path;
    
    return $parts[-2], $parts[-1];
}

# author, filename, revision => upload_path
sub _calculate_upload_path {
    my ($self, $author, $filename, $revision) = @_;
    
    return sprintf 'uploads/%03d/%05d-%s-%s',
        int($revision / 100),
        $revision,
        $author,
        $filename;
}

# author, filename => file
sub _calculate_distribution_file {
    my ($self, $author, $filename) = @_;
    
    $self->dir
         ->file(AUTHOR_DIR, 
                'id', 
                substr($author,0,1), substr($author,0,2), $author,
                $filename)
}

sub remove_distribution {
    my ($self, $destination_path) = @_;
    
    $self->_remove_distribution_file($destination_path);
    $self->packages->save;
    $self->revisions->add('-', $self->_split_path($destination_path));
}

sub _remove_distribution_file {
    my ($self, $destination_path) = @_;

    my ($author, $filename) = $self->_split_path($destination_path);
    my $distribution_file =
        $self->_calculate_distribution_file(
            $author, $filename
        );
    
    unlink $distribution_file;
    
    ### TODO: clean up directories if empty

    $self->packages->remove_distribution($author, $distribution_file);
}

sub log {
    my ($self, $message) = @_;
}

__PACKAGE__->meta->make_immutable;
1;
