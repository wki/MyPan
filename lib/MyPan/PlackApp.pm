package MyPan::PlackApp;
use strict;
use warnings;
use MyPan::Repository;
use Try::Tiny;
use Plack::Request;

use parent 'Plack::Component';
use Plack::Util::Accessor qw(root);

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

sub handle_post {
    my ($self, $env) = @_;
    
    my ($repository_name, $path) = 
        $env->{PATH_INFO} =~ m{\A /* ([^/]+/[^/]+) (?:/+ (.*))? \z}xms;
    
    $self->error(400, 'Repository name required')
        if !$repository_name;
    
    my $repository = MyPan::Repository->new(
        root => join('/', $self->root, $repository_name),
    );
    
    my $message;
    if (!$path) {
        $self->error(400, "Cannot create '$repository_name': already there")
            if $repository->exists;
        $repository->create;
        $message = "Repository '$repository_name' created";
    } else {
        my $request = Plack::Request->new($env);
        
        use Data::Dumper;
        warn Data::Dumper->Dump([$request->uploads], ['uploads']);
        
        $self->error(400, "upload 'file' required")
            if !exists $request->uploads->{file};
        
        $repository->save_file($path, $request->uploads->{file}->path);
        $message = "File '$path' uploaded to '$repository_name'";
    }
    
    return [
        200,
        ['Content-Type' => 'text/plain'],
        [$message],
    ];
}

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
