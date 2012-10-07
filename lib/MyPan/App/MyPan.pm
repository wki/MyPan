package MyPan::App::MyPan;
use Modern::Perl;
use Moose;
use MooseX::Types::Path::Class 'File';
use MyPan::App::Commands;
use namespace::autoclean;

with 'MooseX::SimpleConfig',
     'MooseX::ConfigFromFile',
     'MooseX::Getopt::Strict';

has configfile => (
    traits          => ['Getopt'],
    is              => 'ro',
    default         => \&_build_configfile,
    cmd_aliases     => 'c',
    documentation   => 'an optional config file to get settings from [$HOME/.mypan.yml]',
);

sub _build_configfile {
    my $file = "$ENV{HOME}/.mypan.yml";
    
    return -f $file ? $file : ();
}

has server => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => 'Str',
    # required    => 1,
);

has commands => (
    is          => 'ro',
    isa         => 'MyPan::App::Commands',
    lazy_build  => 1,
);

sub _build_commands { MyPan::App::Commands->new }

# pseudo singleton
my $instance;
sub instance { return $instance }

#
# hacking an expanded usage format into MooseX::Getopt::Basic internals
# not fine but useful here
#
sub _usage_format { "usage: %c %o command [args] -- '%c commands' for list" }

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
    
    say 'Server: ', $self->server // '';
    
    my $command_name = shift @{$self->extra_argv}
        or die 'no command given. try --help';
    
    $self->commands->run_command($command_name);
}

__PACKAGE__->meta->make_immutable;
1;
