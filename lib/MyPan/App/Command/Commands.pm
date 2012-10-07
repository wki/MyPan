package MyPan::App::Command::Commands;
use Modern::Perl;
use Moose;
use List::Util 'max';
use MyPan::App::MyPan;
use namespace::autoclean;

extends 'MyPan::App::Command';

sub run {
    my $self = shift;
    
    my $commands = MyPan::App::MyPan->instance->commands;
    my $max_command_length = max map { length $_ } $commands->all_commands;
    
    say 'Available Commands:';
    say sprintf("  \%-${max_command_length}s - \%s",
                $_, $commands->command($_)->description)
        for sort $commands->all_commands;
}

sub description { 'show this list of commands' }

__PACKAGE__->meta->make_immutable;
1;
