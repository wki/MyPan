package MyPan::App;
use Modern::Perl;
use Moose;
use namespace::autoclean;

with 'MooseX::Getopt::Strict';

#
# very bad but necessary hack.
# Intercept &GetOptions calls and append an 'Argument callback' option
# ('<>' => sub) at the end of the options list enabling to stop parsing
# the command line as soon as the first unknown argument is seen.
# This is needed to avoid failing on '-' options after a command word
# or an unknown option.
#
around new_with_options => sub {
    my ($orig, $class, @args) = @_;

    use Getopt::Long::Descriptive ();

    my $command;

    no warnings 'redefine';
    my $get_options = \&Getopt::Long::Descriptive::GetOptions;
    local *Getopt::Long::Descriptive::GetOptions = sub {
        return $get_options->(@_, '<>', sub { $command = "$_[0]"; die '!FINISH' });
    };

    my $self = $orig->($class, @args);
    unshift @{$self->extra_argv}, $command if $command;
    return $self;
};

sub run {
    my $self = shift;
    
    my $command_name = shift @{$self->extra_argv}
        or die 'no command given. Do not know what to do.';
    
    my $method = $self->can("handle_$command_name")
        or die "no method found for handling command '$command_name'";
    $self->$method;
}

sub handle_list {
    my $self = shift;
    
    say "list -- still TODO";
}

__PACKAGE__->meta->make_immutable;
1;
