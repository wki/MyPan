package MyPan::App::Server;
use Moose;
use namespace::autoclean;

has host => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub send_request {
    my ($self, $method, $url, @data) = @_;
    
    # @data:
    # Path::Class::File object --> file upload
    
    # what to do with return-data?
}


__PACKAGE__->meta->make_immutable;
1;
