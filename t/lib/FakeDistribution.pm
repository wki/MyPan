package FakeDistribution;
use Moose;
use MooseX::Types::Path::Class qw(File Dir);
use File::Temp ();
use Archive::Tar;
use YAML;
use namespace::autoclean;

# useful for testing:
#
# my $dist = FakeDistribution->new(name => 'Some-Module-2.07');
#
# # add files with or without version numbers
# $dist->add_package('Some::Module', '2.07');
# $dist->add_package('Another::Module');
#
# # get a .tar.gz file (Path::Class::File object anywhere in /tmp)
# $dist->tar_gz_file;

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has packages => (
    traits => ['Array'],
    is => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
);

sub add_package {
    my ($self, $package, $version) = @_;

    push @{$self->packages}, [$package, $version];
    $self->clear_tar_gz_file;
}

has temp_dir => (
    is => 'ro',
    isa => Dir,
    coerce => 1,
    lazy_build => 1,
);

sub _build_temp_dir { File::Temp::tempdir(CLEANUP => 1) }

has tar_gz_file => (
    is => 'ro',
    isa => File,
    coerce => 1,
    lazy_build => 1,
    clearer => 'clear_tar_gz_file',
);

sub _build_tar_gz_file  {
    my $self = shift;

    my $tar_gz_file = $self->temp_dir->file($self->name . '.tar.gz');
    
    my $tar = Archive::Tar->new;
    my $base_name = $self->name;
    $tar->add_data("$base_name/MANIFEST", $self->_manifest);
    $tar->add_data("$base_name/META.yml", $self->_meta);
    $tar->add_data("$base_name/" . _pm($_), _content($_))
        for @{$self->packages};
    
    $tar->write($tar_gz_file->stringify, COMPRESS_GZIP);
    
    # warn "TAR: $tar_gz_file";
    return $tar_gz_file;
}

sub _meta {
    my $self = shift;
    
    my ($name, $version) = $self->name =~ m{\A (.*) - ([^-]+) \z}xms;
    
    # not complete but present...
    return Dump({
        abstract => 'test module only',
        name     => $name,
        version  => $version,
        author   => 'somebody',
    });
}

sub _manifest {
    my $self = shift;
    
    return join "\n",
        'MANIFEST',
        'META.yml',
        map { _pm($_) }
        @{$self->packages}
}

sub _pm {
    my $package_and_version = shift;
    
    my $package = $package_and_version->[0];
    $package =~ s{::}{/}xmsg;
    
    return "lib/$package.pm"
}

sub _content {
    my $package_and_version = shift;
    
    my ($package, $version) = @$package_and_version;
    
    return join "\n",
        "package $package;",
        ($version ? "our \$VERSION = '$version';" : ()),
        '1;'
}

__PACKAGE__->meta->make_immutable;
1;
