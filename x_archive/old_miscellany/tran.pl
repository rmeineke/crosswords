#! /usr/bin/perl
use warnings;
use strict;

use PDF::API2;

my $ifile = "pdf.pdf";
my $ofile = "newfile.pdf";
my $pdf   = PDF::API2->open($ifile);
my $fnt   = $pdf->ttfont('Loma-BoldOblique.ttf', -encode => 'utf8');
# Only on the front page
my $page  = $pdf->openpage(1);
my $text  = $page->text;

$page->mediabox('LETTER');

# Create two extended graphic states; one for transparent content
# and one for normal content
my $eg_trans = $pdf->egstate();
my $eg_norm  = $pdf->egstate();

$eg_trans->transparency(0.7);
$eg_norm->transparency(0);

# Go transparent
$text->egstate($eg_trans);
# Black edges
$text->strokecolor('#000000');
# With light green fill
$text->fillcolor('#d3e6d2');
# Text render mode: fill text first then put the edges on top
$text->render(2);
# Diagonal transparent text
$text->textlabel(55, 235, $fnt, 56, "i'm in ur pdf", -rotate => 30);
# Back to non-transparent to do other stuff
$text->egstate($eg_norm);

# …

# Save
$pdf->saveas($ofile);
$pdf->end;
