#!/usr/bin/perl

# rrect for PDF::API2

use strict;
use warnings;
use constant mm => 25.4 / 72;

use PDF::API2;



my $pdf = PDF::API2->new( -file => "$0.pdf" );
my $page = $pdf->page;
$page->mediabox(297/mm, 210/mm);

my $TRANSPARENT = $pdf->egstate; # Called just once
$TRANSPARENT->transparency(0.9);

my $gfx = $page->gfx;
$gfx->egstate( $TRANSPARENT );
$gfx->strokecolor('#aaaaaa');
$gfx->rrect( 135, 26, 405, 405, 3 );
$gfx->stroke;

$pdf->save;

=item $gfx->rrect $x, $y, $w, $h, $r

will draw a rounded rectangle with a corner radius of $r

=cut

sub PDF::API2::Content::rrect {
	my ($gfx, $x, $y, $w, $h, $r) = @_;
$gfx->fill('#dddddd');
	# Top left
	$gfx->arc( $x + $r, $y + $h - $r, $r, $r, 180, 90, 1 );

	# Top right
	$gfx->arc( $x + $w - $r, $y + $h - $r, $r, $r, 90, 0, 0 );

	# Bottom right
	$gfx->arc( $x + $w - $r, $y + $r, $r, $r, 360, 270, 0 );

	# Bottom left
	$gfx->arc( $x + $r, $y + $r, $r, $r, 270, 180, 0 );
$gfx->fill('#dddddd');
	$gfx->close;

	return $gfx;
}
