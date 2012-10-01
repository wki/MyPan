package MyPan::Types;
use strict;
use warnings;
use Path::Class;
use Carp;
use base 'Exporter';

our @EXPORT = qw(
    ExistingDir
    to_Dir
);

sub ExistingDir {
    return sub { -d $_[0] or croak "dir '$_[0]' does not exist" }
}

sub to_Dir {
    return sub { dir($_[0])->absolute->cleanup }
}

1;
