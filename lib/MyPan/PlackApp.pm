package MyPan::PlackApp;
use strict;
use warnings;
use MyPan::Repository;

use parent 'Plack::Component';
use Plack::Util::Accessor qw(root);


sub call {
    my ($self, $env) = @_;

    my $method_name = lc "handle_$env->{REQUEST_METHOD}";

    if ($self->can($method_name)) {
        warn "mypan app, method: $method_name --> handle";
        $self->$method_name($env);
    } else {
        warn "mypan app, method: $method_name --> 405";
        $self->return_405($env);
    }
}

sub handle_post {
    my ($self, $env) = @_;
    
    my ($repo, $path) = 
        $env->{PATH_INFO} =~ m{\A / ([^/+]/[^/+]) (?:/ (.*))? \z}xms;
    
    if (!$repo) {
        $self->return_400($env, 'Repository name required');
    } else {
        my $repository = MyPan::Repository->new(
            root => join('/', $self->root, $repo),
        );
        
        if (!@path) {
            if ($repository->exists) {
                $self->return_400($env, "Cannot create '$name/$version': already there");
            } else {
                ### TODO: error checking
                $repository->create;
            }
        } else {
            # TODO: find uploads.
            $repository->save_file($path);
        }
    }
    
    
    my $message = "POST, path=$env->{PATH_INFO}";
    return [
        200,
        ['Content-Type' => 'text/plain'],
        [$message],
    ];
}

sub handle_delete {
    my ($self, $env) = @_;

}

sub return_400 {
    my ($self, $env, $message) = @_;
    
    $message //= 'Bad Request';
    return [
        400,
        ['Content-Type' => 'text/plain', 'Content-Length' => length $message],
        [$message]
    ];
}

sub return_405 {
    my ($self, $env, $message) = @_;

    $message //= "Cannot handle method: $env->{REQUEST_METHOD}";
    return [
        405,
        ['Content-Type' => 'text/plain', 'Content-Length' => length $message],
        [$message]
    ];
}

1;
