#! /usr/bin/perl 
use strict;
use warnings;


use PDF::API2;


sub chopstr {
    my $font_size = shift;
    my $length = shift;
    my $str = shift;
    
    print "Chopping\n";
    my $l = length $str;
    print $l, " characters\n";
    
    
    
    
    my $pdf = PDF::API2->new();

    my $page = $pdf->page;
    my %font = (
        Helvetica => {
            Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
            Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
            Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
        },
        Times => {
            Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
            Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
            Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
        },
    );
    
    my $txt = $page->text;
    $txt->font( $font{'Times'}{'Roman'}, $font_size);
    print int($txt->advancewidth($str)), " points wide\n";
    print ">$str<\n";
    if (int($txt->advancewidth($str)) > $length) {
        $str = substr($str, 0, $l - 1);
        $str = chopstr($font_size, $length, $str);
    } else {
        return 0;
    }
    return $str;
}

#print chopstr(14, 125, "This is a test string. It is rather long.");
sub get_length {
    my $str = shift;
    my $f = shift;
    
    
    my $pdf = PDF::API2->new();
    
    my $page = $pdf->page;
    my %font = (
        Helvetica => {
            Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
            Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
            Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
        },
        Times => {
            Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
            Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
            Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
        },
    );
    
    my $txt = $page->text;
    $txt->font( $font{'Times'}{'Roman'}, $f);
    
    return int($txt->advancewidth($str));
}




sub split_clue {
    my $clue = shift;
    my $font_size = shift;
    
    my $pdf = PDF::API2->new();

    my $page = $pdf->page;
    my %font = (
        Helvetica => {
            Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
            Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
            Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
        },
        Times => {
            Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
            Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
            Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
        },
    );
    
    my $txt = $page->text;
    $txt->font( $font{'Times'}{'Roman'}, $font_size);
    
    
    print $clue, "\n";
    my @words = split / +/, $clue;
    print "words == ", ($#words + 1), " -- $clue\n";
    my $l = 0;
    my $str = q{};
    my $count = 0;
    while ($l < 125) {
        $str = $str . q{ } . $words[$count];
        $count++;        
        $l = int($txt->advancewidth($str));
        print "$l == $str\n";
    }
    $count--;
    $str = q{};
    my $skip = 0;
    for (my $i = 0; $i < $count; $i++) {
        if ($skip) {
            $str = $str . q{ } . $words[$i];
        } else {
            $str = $str . $words[$i];
        }
        $skip++;
    }
    
    $skip = 0;
    my $left = q{};
    for (my $i = $count; $i < ($#words + 1); $i++) {
        if ($skip) {
            $left = $left . q{ } . $words[$i];
        } else { 
            $left = $left . $words[$i];
        }
        $skip++;
    }
    my $tmp = $left;
    $tmp = q{....} . $left;
    $l = int($txt->advancewidth($tmp));
    return ($str, $tmp);
}

#########################
my $f = 14;
my $l = 125;

my $pdf = PDF::API2->new();

my $page = $pdf->page;
my %font = (
    Helvetica => {
        Bold   => $pdf->corefont( 'Helvetica-Bold',    -encoding => 'latin1' ),
        Roman  => $pdf->corefont( 'Helvetica',         -encoding => 'latin1' ),
        Italic => $pdf->corefont( 'Helvetica-Oblique', -encoding => 'latin1' ),
    },
    Times => {
        Bold   => $pdf->corefont( 'Times-Bold',   -encoding => 'latin1' ),
        Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' ),
        Italic => $pdf->corefont( 'Times-Italic', -encoding => 'latin1' ),
    },
);

my $txt = $page->text;
$txt->font( $font{'Times'}{'Roman'}, $f);

my @strings = (
    "This is a test string. It is rather long.", 
    "This is some gibberishly, delightful rambling.",
    "Shorty.",
    "McShorterson.",
    "One, two, three, four, five, six, seven, eight, nine, and ten.",
    "This is some gibberishly, delight rambling.",
);


my $changes = 1;
while ($changes) {
    $changes = 0;
    my @new_array = ();
    foreach my $s (@strings) {
        if ( get_length($s, $f) > 125 ) {
            print "chop -- $s\n";
            my ($str, $left) = split_clue($s, $f);
            push (@new_array, $str);
            push (@new_array, $left);
            
            $changes++;
        } else {
            push(@new_array, $s);
        }
    }
    @strings = @new_array;
}

print "\n\n\n";


foreach my $c (@strings) {
    print $c, "\n";
}
