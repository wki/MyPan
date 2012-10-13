package MyPan::PlackApp;
use Moose;
use MooseX::NonMoose;
use MooseX::Types::Path::Class 'Dir';
use MyPan::Repository;
use Try::Tiny;
use Path::Class;
use Plack::Request;

extends 'Plack::Component';

has root => (
    is          => 'ro',
    isa         => Dir,
    coerce      => 1,
    required    => 1,
);

sub call {
    my ($self, $env) = @_;

    my $result;
    try {
        my $method_name = lc "handle_$env->{REQUEST_METHOD}";
        $self->error(405 => "cannot handle method '$method_name'")
            if !$self->can($method_name);

        $result = $self->$method_name($env);
    } catch {
        $result = ref $_ eq 'ARRAY'
            ? $_
            : $self->error(400 => "Exception: $_");
    };

    return $result;
}

# CAUTION: must not interfere with Plack::App::File.
#                       scalar dir_list
# GET /repo/ver/log/update.log
# GET /                 --> 2   list repositories
# GET /repo             --> 2   list versions
# GET /repo/ver         --> 3   list modules
# GET /repo/ver/author  --> 4   list modules of this author
sub handle_get {
    my ($self, $env) = @_;

    my $path_info   = dir($env->{PATH_INFO});
    my $nr_path_parts = scalar $path_info->dir_list;

    if ($nr_path_parts < 3) {
        return $self->list_directory($self->root->subdir($path_info))
    } elsif ($nr_path_parts < 5) {
        my $repository_name = join '/', $path_info->dir_list(1,2);
        my ($author)        = $path_info->dir_list(3,1);

        return $self->list_repository($repository_name, $author);
    } elsif ($path_info =~ m{/log/update.log \z}xms) {
        return $self->show_file_content($self->root->file($path_info));
    }
    $self->error(405 => "GET '$env->{PATH_INFO}' not handled internally");
}

sub list_directory {
    my ($self, $dir) = @_;

    $self->error(400 => "Directory '${\$dir->basename}' does not exist")
        if !-d $dir;

    return [
        200,
        ['Content-Type' => 'text/plain'],
        [
            join "\n",
                sort { $a->basename cmp $b->basename }
                grep { $_->basename !~ m{\A _}xms }
                map { $_->relative($self->root) }
                $dir->children
        ],
    ];
}

sub list_repository {
    my ($self, $repository_name, $author) = @_;

    my $repository = MyPan::Repository->new(
        root => $self->root,
        name => $repository_name,
    );

    $self->error(400 => "Repository '$repository_name' does not exist")
        if !$repository->exists;

    return [
        200,
        ['Content-Type' => 'text/plain'],
        [
            join "\n",
                sort
                grep { $author ? m{\A \Q$author\E /}xms : 1 }
                map { s{\A . / .. /}{}xms; $_ }
                keys %{$repository->packages->packages_for}
        ]
    ];
}

sub show_file_content {
    my ($self, $file) = @_;
    
    my $content = $file->slurp;
    
    return [
        200,
        ['Content-Type' => 'text/plain', 'Content-Length' => length $content],
        [ $content ],
    ];
}

# POST /hrko/1.0                                --> create repository
# POST /hrko/1.0/WKI/Catalyst-Thing-0.01.tar.gz --> upload dist
sub handle_post {
    my ($self, $env) = @_;

    my ($repository_name, $path) =
        $env->{PATH_INFO} =~ m{\A /* ([^/]+/[^/]+) (?:/+ (.*))? \z}xms;

    $self->error(400 => 'Repository name required')
        if !$repository_name;

    my $repository = MyPan::Repository->new(
        root => $self->root,
        name => $repository_name,
    );

    my $message;
    my $user = $env->{REMOTE_USER} // '(unknown)';
    if (!$path) {
        $self->error(400 => "Cannot create '$repository_name': already there")
            if $repository->exists;
        $repository->create;
        $repository->log("$user created repository");

        $message = "Repository '$repository_name' created";
    } else {
        my $request = Plack::Request->new($env);

        $self->error(400 => "upload 'file' required")
            if !exists $request->uploads->{file};

        $repository->add_distribution($path, $request->uploads->{file}->path);

        $repository->log("$user uploaded '$path'");
        $message = "File '$path' uploaded to '$repository_name'";
    }

    return [
        200,
        ['Content-Type' => 'text/plain'],
        [$message],
    ];
}

# DELETE /hrko/1.0                          --> whole repo
# DELETE /hrko/1.0/WKI/Thing-0.01.tar.gz    --> one distribution
# DELETE /hrko/1.0/42                       --> revert to revision 42
# DELETE /hrko/1.0/-1                       --> undo last step
sub handle_delete {
    my ($self, $env) = @_;

    my ($repository_name, $path) =
        $env->{PATH_INFO} =~ m{\A /* ([^/]+/[^/]+) (?:/+ (.*))? \z}xms;

    $self->error(400 => 'Repository name required')
        if !$repository_name;

    my $repository = MyPan::Repository->new(
        root => $self->root,
        name => $repository_name,
    );
    
    $self->error(400 => "Repository '$repository_name' does not exist")
        if !$repository->exists;

    my $user = $env->{REMOTE_USER} // '(unknown)';
    my $message;
    
    if (! defined $path || $path eq '') {
        # delete entire repository
        $repository->dir->traverse(\&_remove_recursive);
        $message = "removed repository '$repository_name'";
    } elsif ($path eq '-1') {
        # undo last step
        $self->error(400 => 'Undo not implemented yet');
    } elsif ($path =~ m{\A \d+ \z}xms) {
        # revert to revision x
        $self->error(400 => 'Revert not implemented yet');
    } else {
        # delete one distribution
        $repository->remove_distribution($path);
        $repository->log("$user removed '$path'");
        $message = "removed distribution '$path'";
    }
    
    return [
        200,
        ['Content-Type' => 'text/plain'],
        [$message],
    ];
}

sub _remove_recursive {
    my ($child, $cont) = @_;

    $cont->() if -d $child;
    $child->remove;
}

sub error {
    my ($self, $code, $message) = @_;

    $code //= 400;
    $message //= 'Bad Request';
    my $result = [
        $code,
        ['Content-Type' => 'text/plain', 'Content-Length' => length $message],
        [$message]
    ];

    die $result if !defined wantarray;
    return $result;
}

1;
