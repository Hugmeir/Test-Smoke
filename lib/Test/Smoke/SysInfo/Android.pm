package Test::Smoke::SysInfo::Android;
use warnings;
use strict;

use base 'Test::Smoke::SysInfo::Linux';

=head1 NAME

Test::Smoke::SysInfo::Android - Object for specific Android info.

=head1 DESCRIPTION

=head2 $si->prepare_os()

Use os-specific tools to find out more about the operating system.

=cut

use Config;
use POSIX;
sub prepare_os {
    my $self = shift;
    my @uname = POSIX::uname();
    
    my $osname = $^O;
    my $osvers = `getprop ro.build.version.release` || $Config{osvers};
    my $desc   = `getprop ro.build.description` || '';
    chomp $osvers;
    chomp $desc;
    
    my $linux_ver = $self->_os();
    
    $self->{__os} = "$osname $osvers ($desc) [$linux_ver]";
}

1;
