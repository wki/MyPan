package MyPan::App::Server;
use Moose;
use URI;
use HTTP::Request::Common;
use LWP::UserAgent;
use Carp;
use namespace::autoclean;

has host => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub _url {
    my $self = shift;
    my $path = shift // '';
    
    my $url = "http://${\$self->host}/$path";
    warn "URL=$url";
    return $url;
}

sub get {
    my ($self, $path) = @_;
    
    $self->send_request(GET $self->_url($path));
}

sub post {
    my ($self, $path, @data) = @_;
    
    $self->send_request(
        POST $self->_url($path),
        'Content-Type' => 'multipart/form-data',
        Content => \@data,
    );
}

sub send_request {
    my ($self, $request) = @_;
    
    my $ua = LWP::UserAgent->new;
    my $response = $ua->request($request);
    
    croak $response->status_line if !$response->is_success;
    
    return $response->decoded_content;
}

__PACKAGE__->meta->make_immutable;
1;
