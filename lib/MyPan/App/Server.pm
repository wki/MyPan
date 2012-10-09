package MyPan::App::Server;
use Moose;
use URI;
use HTTP::Headers;
use HTTP::Request::Common;
use LWP::UserAgent;
use Carp;
use MyPan::App::MyPan;
use namespace::autoclean;

has host => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub _url {
    my $self = shift;
    my $path = shift // '';
    
    return "http://${\$self->host}/$path";
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
    
    my $app = MyPan::App::MyPan->instance;
    
    if ($app->has_username) {
        my $header = HTTP::Headers->new;
        $header->authorization_basic($app->username, $app->password // '');
        
        $request->header($_ => $header->header($_))
            for $header->header_field_names;
    }
    
    my $ua = LWP::UserAgent->new;
    my $response = $ua->request($request);
    
    croak $response->status_line if !$response->is_success;
    
    return $response->decoded_content;
}

__PACKAGE__->meta->make_immutable;
1;
