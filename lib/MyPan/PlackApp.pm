package MyPan::PlackApp;
use Moose;
use MooseX::NonMoose;
use MooseX::Types::Path::Class 'Dir';
use MyPan::Repository;
use Try::Tiny;
use Path::Class;
use Plack::Request;

# use parent 'Plack::Component';
# use Plack::Util::Accessor qw(root);

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
        $self->error(405, "cannot handle method '$method_name'")
            if !$self->can($method_name);

        $result = $self->$method_name($env);
    } catch {
        if (ref $_ eq 'ARRAY') {
            $result = $_;
        } else {
            $result = $self->error(400, "Exception: $_");
        }
    };

    return $result;
}

# CAUTION: must not interfere with Plack::App::File.
#                       scalar dir_list
# GET /                 --> 2   list repositories
# GET /repo             --> 2   list versions
# GET /repo/ver         --> 3   list modules
# GET /repo/ver/author  --> 4   list modules of this author
sub handle_get {
    my ($self, $env) = @_;

    my $path_info   = dir($env->{PATH_INFO});
    my $path_length = scalar $path_info->dir_list;

    if ($path_length < 3) {
        return $self->list_directory($self->root->subdir($path_info))
    } else {
        my $repository_name = join '/', $path_info->dir_list(1,2);
        my ($author)        = $path_info->dir_list(3,1);

        return $self->list_repository($repository_name, $author);
    }
    $self->error(405 => "GET '$env->{PATH_INFO}' not handled internally");
}

sub list_directory {
    my ($self, $dir) = @_;

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

# POST /hrko/1.0                                --> create repository
# POST /hrko/1.0/WKI/Catalyst-Thing-0.01.tar.gz --> upload dist
sub handle_post {
    my ($self, $env) = @_;

    my ($repository_name, $path) =
        $env->{PATH_INFO} =~ m{\A /* ([^/]+/[^/]+) (?:/+ (.*))? \z}xms;

    $self->error(400, 'Repository name required')
        if !$repository_name;

    my $repository = MyPan::Repository->new(
        root => $self->root,
        name => $repository_name,
    );

    my $message;
    if (!$path) {
        $self->error(400, "Cannot create '$repository_name': already there")
            if $repository->exists;
        $repository->create;
        $message = "Repository '$repository_name' created";
    } else {
        my $request = Plack::Request->new($env);

        # use Data::Dumper;
        # warn Data::Dumper->Dump([$request->uploads], ['uploads']);

        $self->error(400, "upload 'file' required")
            if !exists $request->uploads->{file};

        warn "Upload ($path) from file (${\$request->uploads->{file}->path}) size: " . -s $request->uploads->{file}->path;
        $repository->add_distribution($path, $request->uploads->{file}->path);
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

}

sub error {
    my ($self, $code, $message) = @_;

    $code //= 400;
    $message //= 'Bad Request';
    my $result = [
        400,
        ['Content-Type' => 'text/plain', 'Content-Length' => length $message],
        [$message]
    ];

    die $result if !defined wantarray;
    return $result;
}

1;
