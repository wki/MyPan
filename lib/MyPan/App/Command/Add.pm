package MyPan::App::Command::Add;
use Moose;
use Path::Class;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub description { 'add a distribution to a repository' }

# args: module-spec, repo/version [/author]
# creates POST /repo/ver/author/dist
sub run {
    my ($self, $args) = @_;
    
    die 'Add: 2 arguments (dist-file and repository) needed'
        if scalar @$args < 2;
    
    ### TODO: allow cpan://, backpan:// or http://host/... URLs also
    my $dist_file = file(shift @$args);
    die "Dist file '$dist_file' does not exist"
        if !-f $dist_file;
    
    my $target_repo_path = shift @$args;
    
    $self->server->post(
        "$target_repo_path/${\$dist_file->basename}",
        file => [ $dist_file->stringify ]
    );
}

__PACKAGE__->meta->make_immutable;
1;
