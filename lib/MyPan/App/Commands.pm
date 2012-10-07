package MyPan::App::Commands;
use Moose;
use Module::Load;
use Module::Pluggable search_path => 'MyPan::App::Command',
                      sub_name => '_commands';
# don't use -- conflicts with Module::Pluggable
# use namespace::autoclean;

has package_for_command => (
    traits      => ['Hash'],
    is          => 'ro',
    isa         => 'HashRef',
    lazy_build  => 1,
    handles     => {
        all_commands => 'keys',
        get_package  => 'get',
        has_command  => 'exists',
    },
);

sub _build_package_for_command {
    return {
        map { m{:: (\w+) \z}xms ? (lc $1 => $_) : () }
        __PACKAGE__->_commands
    }
}

sub command {
    my ($self, $command_name) = @_;
    
    my $command_package = $self->get_package($command_name)
        or die "Unknown command: '$command_name'";
    
    load $command_package;
    
    return $command_package->new();
}

sub run_command {
    my ($self, $command_name) = @_;
    
    $self->command($command_name)->run;
}

__PACKAGE__->meta->make_immutable;
1;
