#! /usr/bin/perl -w
use strict;
# BEGIN { die "You must be on MSWin32 for this!\n" unless $^O eq 'MSWin32' }

use File::Spec;
use FindBin;
use lib File::Spec->catdir( $FindBin::Bin, 'lib' );
use Test::Smoke::Util qw( Configure_win32 );

use vars qw( $VERSION $conf );
$VERSION = '0.001';

=head1 NAME

W32Configure.pl - Configure a Makefile for the Windows port of perl

=head1 SYNOPSIS

  S:\Smoke>perl W32Configure.pl -m dmake -d ..\perl-current -- [config options]

=head1 DESCRIPTION

B<This is still an alpha interface, anything could change>

This is a raw interface to C<Test::Smoke::Util::Configure_win32()>.
Just pass it options for the F<Makefile> after a dubble dash '--'.
See L<Test::Smoke::Util/Configure_win32> for options you can pass!

The result is B<[builddir]\win32\smoke.mk> a makefile that has all
the configure options you passed worked into it. 

This could help debugging.

=cut

my %opt = (
    ddir   => '',
    maker  => '',
    v      => 0,

    config => '',
    help   => 0,
    man    => 0,
);

use Getopt::Long;
GetOptions( \%opt,
    'ddir|d=s', 'maker|m=s', 'v|verbose+',

    'man', 'help|h',

    'config|c=s',
) or do_pod2usage( verbose => 1 );

$opt{man}  and do_pod2usage( verbose => 2, exitval => 0 );
$opt{help} and do_pod2usage( verbose => 1, exitval => 0 );

if ( $opt{config} && -f $opt{config} ) {
    require $opt{config};

    foreach my $option ( keys %opt ) {
        if ( $option eq 'maker' ) {
            $opt{type} ||= $conf->{w32args}[3];
        } elsif ( exists $conf->{ $option } ) {
            $opt{ $option } ||= $conf->{ $option }
        }
    }
}

$opt{maker} ||= 'nmake';
$opt{ddir} && -d $opt{ddir} or do_pod2usage( verbose => 0 );

my $c_args = join " ", @ARGV;
my @cfgvars = ( 'osvers=' . get_Win_version() );

chdir $opt{ddir} or die "Cannot chdir($opt{ddir}): $!";
Configure_win32( "./Configure $c_args", $opt{maker}, @cfgvars );

sub do_pod2usage {
    eval { require Pod::Usage };
    if ( $@ ) {
        print <<EO_MSG;
Usage: $0 -t <type> -d <directory> [options]

Use 'perldoc $0' for the documentation.
Please install 'Pod::Usage' for easy access to the docs.

EO_MSG
        my %p2u_opt = @_;
        exit( exists $p2u_opt{exitval} ? $p2u_opt{exitval} : 1 );
    } else {
        Pod::Usage::pod2usage( @_ );
    }
}

sub get_Win_version {
    my @osversion = eval { Win32::GetOSVersion() };
    $@ and @osversion = ( '', 4, 0 ); # The default is NT 4.0

    my $win_version = join '.', @osversion[ 1, 2 ];
    $win_version .= " $osversion[0]" if $osversion[0];

    return $win_version;
}

=head1 SEE ALSO

L<Test::Smoke::Util>

=head1 COPYRIGHT

(c) 2002-2003, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * http://www.perl.com/perl/misc/Artistic.html

=item * http://www.gnu.org/copyleft/gpl.html

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
