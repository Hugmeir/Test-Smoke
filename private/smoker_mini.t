#! /usr/bin/perl -w
use strict;
use Data::Dumper;
$| = 1;

# $Id$

use Cwd;
use FindBin;
use File::Spec::Functions;
#use lib catdir( $FindBin::Bin, updir, 'lib' );
#use lib catdir( $FindBin::Bin, updir );
use lib $FindBin::Bin;

use SmokertestLib;
use Test::More 'no_plan';
pass( $0 );

use Test::Smoke::BuildCFG;
use_ok( 'Test::Smoke::Smoker' );

{
    local *DEVNULL;
    open DEVNULL, ">". File::Spec->devnull;
    my $stdout = select( DEVNULL ); $| = 1;

    my $cfg    = "--mini\n=\n\n-DDEBUGGING";
    my $config = Test::Smoke::BuildCFG->new( \$cfg );

    my $ddir   = catdir( $FindBin::Bin, 'perl' );
    my $l_name = catfile( $ddir, 'mktest.out' );
    local *LOG;
    open LOG, "> $l_name" or die "Cannot open($l_name): $!";

    my $smoker = Test::Smoke::Smoker->new( \*LOG => {
        ddir => $ddir,
        cfg  => $config,
    } );

    isa_ok( $smoker, 'Test::Smoke::Smoker' );
    $smoker->mark_in;

    my $cwd = cwd();
    chdir $ddir or die "Cannot chdir($ddir): $!";

    $smoker->log( "Smoking patch 19000\n" );

    for my $bcfg ( $config->configurations ) {
        $smoker->mark_out; $smoker->mark_in;
        $smoker->make_distclean;
        ok( $smoker->Configure( $bcfg ), "Configure $bcfg" );

        $smoker->log( "\nConfiguration: $bcfg\n", '-' x 78, "\n" );
        my $stat = $smoker->make_;
        is( $stat, Test::Smoke::Smoker::BUILD_MINIPERL(), 
            "Could not build anything but 'miniperl'" );
        $smoker->log( "Unable to make anything but miniperl",
                      " in this configuration\n" );

        ok( $smoker->make_test_prep, "make test-prep" );
        local $ENV{PERL_FAIL_MINI} = $bcfg->has_arg( '-DDEBUGGING' ) ? 1 : 0;
        ok( $smoker->make_minitest( "$bcfg" ), "make minitest" );
    }

    $smoker->mark_out;

    ok( make_report( $ddir ), "Call 'mkovz.pl'" ) or diag( $@ );
    ok( my $report = get_report( $ddir ), "Got a report" );
    like( $report, qr/^M - M -\s*$/m, "Got all M's for default config" );
    like( $report, qr/^Summary: FAIL\(M\)\s*$/m, "Summary: FAIL(M)" );
    like( $report, qr/^
        $^O\s*
        \[minitest\s*\]
        -DDEBUGGING\ --mini\s+
        t\/smoke\/minitest\.+FAILED\ at\ test\ 2
    /xm, "Failures report" );
          

    select( DEVNULL ); $| = 1;
    $smoker->make_distclean;
    clean_mktest_stuff( $ddir );
    chdir $cwd;

    select $stdout;
}

