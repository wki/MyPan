package MyPan::Role::HTTP;
use Moo::Role;
# use HTTP::Tiny;
use LWP::Simple;
use Carp;

sub http_get {
    my ($self, $url) = @_;
    
    return get $url;
    # my $http = HTTP::Tiny->new;
    # my $response = $http->get($url);
    # 
    # croak "Response failed: $response->{reason}" if !$response->{success};
    # 
    # return $response->{content};
}

1;
