package MyPan::App::MyPan;
use Modern::Perl;
use Moose;
use MyPan::App::Commands;
use namespace::autoclean;

with 'MooseX::Getopt::Strict';

has commands => (
    is => 'ro',
    isa => 'MyPan::App::Commands',
    lazy_build => 1,
);

sub _build_commands { MyPan::App::Commands->new }

# pseudo singleton
my $instance;
sub instance { return $instance }

#
# hacking an expanded usage format into MooseX::Getopt::Basic internals
# not fine but useful here
#
sub _usage_format { "usage: %c %o command [args] -- try commands for full list" }

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

    my $self = $instance = $orig->($class, @args);
    unshift @{$self->extra_argv}, $command if $command;
    return $self;
};

sub run {
    my $self = shift;
    
    my $command_name = shift @{$self->extra_argv}
        or die 'no command given. try --help';
    
    $self->commands->run_command($command_name);
}

__PACKAGE__->meta->make_immutable;
1;
