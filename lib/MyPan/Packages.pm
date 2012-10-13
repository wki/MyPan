package MyPan::Packages;
use Moose;
use MooseX::Types::Path::Class qw(File);
use Carp;
use Try::Tiny;
use DateTime;
use MyPan::Distribution;
use namespace::autoclean;

has file => (
    is          => 'ro',
    isa         => File,
    coerce      => 1,
    required    => 1,
);

# author_distribution_path => [ {package, version}, ... ]
has packages_for => (
    traits      => ['Hash'],
    is          => 'rw',
    isa         => 'HashRef',
    default     => sub { {} },
);

# base package name => 1, eg Moo => 1, Class-Accessor-Lite => 1
has seen_package => (
    is          => 'rw',
    isa         => 'HashRef',
    default     => sub { {} },
);

sub BUILD {
    my $self = shift;

    my $fh = $self->file->open('<:gzip') or return;
    
    while (my $line = <$fh>) {
        last if $line =~ m{\A \s* \z}xms;
    }

    while (my $line = <$fh>) {
        chomp $line;

        my ($package, $version, $author_distribution_path) =
            split qr{\s+}, $line;
        
        push @{$self->packages_for->{$author_distribution_path}},
            { package => $package, version => $version };
    }
    
    $self->seen_package->{_strip_version($_)} = 1
        for keys %{$self->packages_for};
}

sub _strip_version {
    my $distribution = shift;
    
    $distribution =~ s{-\d.* \z}{}xms;
    
    return $distribution;
}

sub has_distribution {
    my ($self, $author, $filename) = @_;

    my $dist = MyPan::Distribution->new(
        author => $author,
        file => $filename
    );
    
    return exists $self->packages_for->{$dist->author_distribution_path};
}

sub add_distribution {
    my ($self, $author, $file) = @_;

    my $dist = MyPan::Distribution->new(
        author => $author,
        file => $file
    );
    
    $self->packages_for->{$dist->author_distribution_path} = $dist->packages;
}

sub similar_distributions {
    my ($self, $file) = @_;

    my $stripped_name = _strip_version($file->basename);
    
    return grep { m{/ \Q$stripped_name\E -\d}xms }
           keys %{$self->packages_for};
}

sub remove_distribution {
    my ($self, $author, $file) = @_;

    my $dist = MyPan::Distribution->new(
        author => $author,
        file => $file
    );
    
    delete $self->packages_for->{$dist->author_distribution_path};
}

sub save {
    my $self = shift;
    my $file = shift || $self->file;
    
    my $fh = $file->open('>:gzip')
        or croak "cannot open file '$file' for writing: $!";

    my @packages =
        sort { $a->[0] cmp $b->[0] }
        map {
            my $distribution = $_;
            
            map { [ $_->{package}, $_->{version}, $distribution ] }
            @{$self->packages_for->{$distribution}}
        }
        keys %{$self->packages_for};

    my $now = DateTime->now(time_zone => 'local')->strftime('%a, %e %b %y %T %Z');

    print $fh <<HEADER;
File:         02packages.details.txt
URL:          http://www.perl.com/CPAN/modules/02packages.details.txt
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   MyPan Library
Line-Count:   ${\scalar @packages}
Last-Updated: $now

HEADER

    printf $fh "%-60s %-20s %s\n", @$_
        for @packages;

    $fh->close;
}

__PACKAGE__->meta->make_immutable;
1;
