package MyPan::Repository;
use Moo;
use Try::Tiny;
use Path::Class;
use MyPan::Types;
use MyPan::Const;

with 'MyPan::Role::HTTP';

has root => (
    is       => 'ro',
    required => 1,
    coerce   => to_Dir,
);

has name => (
    is => 'ro',
    required => 1,
);

has dir => (
    is => 'lazy',
);

sub _build_dir { $_[0]->root->subdir($_[0]->name) }

sub revision_file { $_[0]->dir->file('log/revisions.txt') }

has revisions => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_revisions {
    my $self = shift;

    my @revisions;
    try {
        @revisions =
            map {
                m{\A 0* (\d+) \s+ ([+-]) \s+ ([A-Z]+) \s+ (.*) \z}
                    ? {
                        revision  => $1,
                        operation => $2,
                        author    => $3,
                        file      => $4 }
              : m{\A 0* (\d+) \s+ (>) \s+ 0* (\d+) \z}
                    ? {
                        revision  => $1,
                        operation => $2,
                        revert_to => $3
                    }
              : ()
            }
            $self->revision_file->slurp(chomp => 1);
    };

    return \@revisions;
}

sub next_revision {
    my $self = shift;
    
    scalar @{$self->revisions}
        ? $self->revisions->[-1]->{revision} + 1
        : 0;
}

sub exists { -d $_[0]->dir }

sub create {
    my $self = shift;

    warn "create repository ${\$self->name}";

    if (!$self->exists) {
        $self->root->mkpath;
        $self->update_global_files;
        $self->dir->mkpath;
        $self->dir->subdir($_)->mkpath
            for (UPLOAD_DIR, LOG_DIR, AUTHOR_DIR, MODULE_DIR);

        symlink $self->global_dir->file(RECENT_FILE)
            => $self->dir->file(RECENT_FILE);
        symlink $self->global_dir->file(MAILRC_FILE)
            => $self->dir->subdir(AUTHOR_DIR)->file(MAILRC_FILE);
        symlink $self->global_dir->file(MODLIST_FILE)
            => $self->dir->subdir(MODULE_DIR)->file(MODLIST_FILE);

        $self->update_package_file;
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

            warn "loading URL: $url";
            $file->spew(http_get($url));
        }
    }
}

sub update_package_file {
    my $self = shift;

    ### TODO
}

sub add_distribution {
    my ($self, $destination_path, $source_file) = @_;
    
    my ($author, $filename) = $self->_split_path($destination_path);
    
    my $upload_file =
        $self->dir->file(
            $self->_calculate_upload_path(
                $author, $filename, $self->next_revision
            )
        );
    
    $upload_file->dir->mkpath if !-d $upload_file->dir;
    $upload_file->spew(file($source_file)->slurp);
    
    my $distribution_file =
        $self->_calculate_distribution_file(
            $author, $filename
        );
    
    $distribution_file->dir->mkpath if !-d $distribution_file->dir;
    symlink $upload_file => $distribution_file;
    
    # TODO: is there a replacement? --> delete
    
    my $fh = $self->revision_file->open('>>');
    printf $fh "%05d + %s %s\n",
        $self->next_revision,
        $author, 
        $filename;
    
    $self->clear_revisions;
}

sub _split_path {
    my ($self, $path) = @_;
    
    my @parts = split '/', $path;
    
    return $parts[-2], $parts[-1];
}

sub _calculate_upload_path {
    my ($self, $author, $filename, $revision) = @_;
    
    return sprintf '%03d/%05d-%s-%s',
        int($revision / 100),
        $revision,
        $author,
        $filename;
}

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
}

sub log {
    my ($self, $message) = @_;
}

1;
