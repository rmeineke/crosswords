#!/usr/bin/perl

use Carp;
use warnings;
use strict;

use PDF::API2;

sub process_clues {
    print "process_clues\n";
    my $across_ref = shift;
    my $down_ref = shift;
    
    my $col_width = 125;
    
    my @new_clues;    
    for (my $i = 14; $i > 7; $i--) {
        @new_clues = ();
        print $i, "\n";    
       
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
    $txt->font( $font{'Times'}{'Roman'}, $i);
    
    
        foreach my $a (@$across_ref) {
            #print $a, "\n";
            if (int($txt->advancewidth($a)) > $col_width) {
                print "this is too long --- \n";
                print $a, "\n\n";
            } else {
                push (@new_clues, $a);
            }
        }#foreach across
        
        foreach my $d (@$down_ref) {
            #print $d, "\n";
            if (int($txt->advancewidth($d)) > $col_width) {
                print "this is too long --- \n";
                print $d, "\n\n";
            } else {
                push (@new_clues, $d);
            }
        }#foreach down
              
    }#for fontsize
    
    foreach my $c (@new_clues) {
        #print $c, "\n";
    }
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
    $txt->font( $font{'Times'}{'Roman'}, 8);
    
    
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
    $tmp = q{    } . $left;
    $l = int($txt->advancewidth($tmp));
    return ($str, $left);
}
##############################################################


sub generate_pdf {
    print "Generate pdf\n";
    
    my $width   = shift;
    
    print "width: ", $width, "\n";
    
    #405 is 3/4 of a 7.5 inch wide page
    my $sq_size = int(405 / ($width - 1));
    print "sq_size: ", $sq_size, "\n";
    my $matrix_ref = shift;
    my $across_ref = shift;
    my $down_ref = shift;
    
    #print "\n::::::::::::::: MATRIX :::::::::::::::\n";
    my $count        = 0;
    my $grey_squares = 0;
    my $height       = $width;
    for ( my $i = 1; $i < $height; $i++ ) {
        for ( my $j = 1; $j < $width; $j++ ) {

            #print $matrix_ref->[$i][$j];
            if ( $matrix_ref->[$i][$j] eq 'y' ) {
                $count++;
            }
            if ( $matrix_ref->[$i][$j] eq '.' ) {
                $grey_squares++;
            }
        }

        #print "\n";
    }


    my $fn = '00rsm.pdf';
    unlink($fn);

    my $pdf = PDF::API2->new( -file => "$fn" );

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

    my $st_x = 171;
    my $st_y = 441 - $sq_size;
    my $box = $page->gfx;
    $box->fillcolor('#dddddd');
    my $x;
    my $y;
    #my $height = $width;
    $count = 0;
    
    
    #start drawing the actual puzzle grid 
    
    
    #this draws the gray boxes 
    #and puts the clue numbers in the boxes
    my $txt = $page->text;
    $txt->font( $font{'Times'}{'Roman'}, 9 );
    $txt->fillcolor('#000000');

    for ( my $i = 0; $i < $height - 1; $i++ ) {
        $y = $st_y - ($i * $sq_size);
        for ( my $j = 0; $j < $width - 1; $j++ ) {
            $x = $st_x + ($j * $sq_size); 
            #print "$i, $j -- $x, $y";
            if ($matrix_ref->[$i + 1][$j + 1] eq '.') {   
                #print " -- gray";                  
                #x, y, width, height
                $box->rect( $x, $y, $sq_size, $sq_size );
                $box->fill;
            }
            #print "\n";
            if ( $matrix_ref->[$i + 1][$j + 1] eq 'y' ) {
                $count++;
                $txt->translate( ($x + 1), ($y + 19));
                $txt->text("$count");
                #$txt->text("R");
            }
        }   
    }
    print "count ::::::::::: $count\n";
    
    #################
    # GRID Lines 
    
    #set up the line for grid drawing
    my $line = $page->gfx;
    $line->linewidth(.5);
    $line->strokecolor('#000000');

    #upperleft of the grid
    $st_x = 171;
    $st_y = 441;
    $line->move( $st_x, $st_y );
    $width--;
    #horizontal
    for ( my $i = -1; $i < $width; $i++ ) {
        $line->line( $st_x + 405, $st_y );
        $line->stroke;

        $st_y -= $sq_size;
        $line->move( $st_x, $st_y );
    }

    #vertical
    $st_x = 171;
    $st_y = 441;
    $line->move( $st_x, $st_y );
    for ( my $i = -1; $i < $width; $i++ ) {
        $line->line( $st_x, $st_y - 405 );
        $line->stroke;

        $st_x += $sq_size;
        $line->move( $st_x, $st_y );
    }
    
#do this in a loop to determine the 
#max font size ....


    my $font_size = 5;
    $txt->font( $font{'Helvetica'}{'Roman'}, $font_size );
    $txt->fillcolor('#000000'); 
    
    
    ##Move to the Upper left
    #$st_x = 36;
    #$st_y = 756;
    #$txt->translate($st_x, $st_y);
    
    
    #first we are going to massage the clues to 
    #make the line lengths fit.
    my @new_across;
    foreach my $clue (@$across_ref) {
        my $l = int($txt->advancewidth($clue));
        
        #125 is one quarter the width of a 7.5 inch page
        #this will leave 4 columns of clues
        if ($l <= 125) {
            push(@new_across, $clue);
             next;
        }
        my $part;
        my $leftover;
        ($l, $part, $leftover) = split_clue($clue);
        push(@new_across, $part);
 
        while ($l > 125) {
            ($l, $part, $leftover) = split_clue($leftover);
            push(@new_across, q{      } . $part);
        }#while         
        #push (@new_across, q{      } . $leftover);

    }#foreach
    
    foreach my $clue (@$down_ref) {
        my $l = int($txt->advancewidth($clue));
        if ($l <= 125) {
            push(@new_across, $clue);
            next;
        }
        my $part;
        my $leftover;
        ($l, $part, $leftover) = split_clue($clue);
        push(@new_across, $part);
        while ($l > 125) {
            ($l, $part, $leftover) = split_clue($leftover);
            push(@new_across, q{      } . $part);
        }#while         
        #push (@new_across, q{      } . $leftover);
    }#foreach
    
    my $lines = @new_across;
    #print " * * lines == ", $lines, "\n";
    
    my $cnt = 0;
    my $line_cnt = 0;
    my $brk1 = 0;
    my $brk2 = 0;
    my $brk3 = 0;
    foreach my $line (@new_across) {
        if ($line eq 'rsmrsmrsm') {
            #print $line, "\n";
            $line_cnt++;
            $cnt += 2;
        } else {
            $cnt += 12;
        }
    }
    print "line_cnt -- brk1 -- brk2 -- brk3\n";
    print "$line_cnt -- $brk1 -- $brk2 -- $brk3\n";    
    
    
    print "cnt = $cnt\n";
    
    
    #back to the upper left 
    $st_x = 36;
    $st_y = 756;
    $line->move( $st_x, $st_y );
    

    $font_size = 12;
    my $line_height = $font_size + 2;
    foreach my $clue (@new_across) {
        
        #set the across/down heading bold
        if ( $clue =~ m/^:/ ) {
            $txt->font( $font{'Times'}{'Bold'}, $font_size );
            $txt->fillcolor('#000000'); 
            #print "..............................$clue\n";
        } else {
            $txt->font( $font{'Times'}{'Roman'}, $font_size );
            $txt->fillcolor('#000000'); 
        }
  
        $st_y -= $line_height;
        $txt->translate( $st_x, $st_y);
        $txt->text("$clue");
    }
    
    $pdf->save;
    $pdf->end();

    print " * * * Generate pdf returns\n";
}
##############################
##############################
##############################
my $file_in = "puz.puz";
open my $IN, '<', $file_in or croak;

binmode($IN);

my $bytesRead;
my $buffer;

#skip past the checksums
seek $IN, 0x2c, 0;

#read width and height
read $IN, $buffer, 2;
my $width  = ord substr $buffer, 0, 1;
my $height = ord substr $buffer, 1, 1;

my $characters = $width * $height;
print "Num characters == $characters\n";

read $IN, $buffer, 2;

my $num_clues = ord $buffer;
print "Num clues == $num_clues\n";

#skip next 4
read $IN, $buffer, 4;

#read past the solution string
read $IN, $buffer, $characters;

#lay the solution string out in a matrix
my @matrix;


#add an extra row/column .... 
$width++;
$height++;
print $width . " x " . $height . "\n";

#lay some dots around the top and left
for ( my $i = 0; $i < $height; $i++ ) {
    $matrix[$i][0] = '.';
    $matrix[0][$i] = '.';
}

#read in and drop into the matrix the 
#dots and dashes that indicate clues
#and blanks
for ( my $i = 1; $i < $height; $i++ ) {
    for ( my $j = 1; $j < $width; $j++ ) {
        read $IN, $buffer, 1;
        my $str = $buffer;
        $matrix[$i][$j] = $str;
    }
}


#collect the clues into the @strings array
my $str = '';
my @strings;
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {
    $str .= $buffer;
    
    if ( $buffer eq "\0" ) {
        push @strings, $str;
        #Sprint "..... $str\n";
        $str = '';
    }
}

my $title = shift @strings;
print $title, "\n";
my $author = shift @strings;
print $author, "\n";
my $copyright = shift @strings;
print $copyright, "\n\n";

my $num_strings = @strings;
print "Num clue strings == $num_strings\n";

#$num_strings = @strings;
#print "Num strings == $num_strings\n";

#print join(', ', @strings);
#$l = @strings;
#print "Total number of strings == $l\n";

#we are done w/ the input
close $IN;
#my $l = @matrix;

#tweaking the clue matrix here
#
#this will change any dashes to the letter 'y'
#if they will need to be numbered
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
        next if $matrix[$i][$j] eq '.';
        if ( $i == 1 || $matrix[ ( $i - 1 ) ][$j] eq '.' ) {
            $matrix[$i][$j] = 'y';           
        }#if
    }#for
}#for

for ( my $j = 0; $j < $width; $j++ ) {
    for ( my $i = 0; $i < $height; $i++ ) {
        next if ( $matrix[$i][$j] eq '.' || $matrix[$i][$j] eq 'y' );
        if ( $j == 1 || $matrix[$i][ ( $j - 1 ) ] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }#if
    }#for
}#for

#count the clues across
my $num_across = 0;
my $num_down = 0;
my $clue_count = 0;
my @clue_order;
my $numbered = 0;

my @across;
my @down;

#parse the clues and then separate them into across and down
for ( my $i = 1; $i < $height; $i++ ) {
    for ( my $j = 1; $j < $width; $j++ ) {
        next if $matrix[$i][$j] eq '.';
        
        my $a = 0;
        my $d = 0;
        
        #any position and preceded by a dot (.)
        if ( $matrix[$i][$j] eq 'y' && $matrix[$i][($j - 1)] eq '.' ) {
            $num_across++;
            $a++;
            push(@clue_order, 'a');
        }#if
        
        if ( $matrix[$i][$j] eq 'y' && $matrix[($i - 1)][$j] eq '.' ) {
            $num_down++; 
            $d++;
            push(@clue_order, 'd');
        }#if
        
        #set up the individual across and down lists
        if ($a || $d) {
            $clue_count++;
            if ($a) {
                push(@across, $clue_count);
            }
            if ($d) {
                push(@down, $clue_count);
            }
        }#if
    }#for
}#for
#print "\n";
#print "num_across   == $num_across\n";
#print "num_down     == $num_down\n";
#print "clue_count   == $clue_count\n";
#print @clue_order;
#my $ttl_clues = @clue_order;
#print "ttl_clues    == $ttl_clues\n";
#print "\n\n:::::::::::::: Across ::::::::::::::::\n";
#print join( ", ", @across);
#print "\n\n:::::::::::::: Down ::::::::::::::::\n";
#print join(", ", @down);
#print "\n\n:::::::::::::: Order ::::::::::::::::\n";
#print join(", ", @clue_order);
#print "\n\n";


my @clue_list;
my @across_list;
my @down_list;
foreach my $dir (@clue_order) {
    my $clue = shift(@strings);
    if ($dir eq 'a') {
        push(@across_list, $clue);
    } else {
        push(@down_list, $clue);  
    }
}

#######################3rsm
# this is to line up the single 
# number clues with the double letter clues
# 
my $length = @across_list;
for (my $i = 0; $i < $length; $i++) {
    if ($across[$i] < 10) {
        $across_list[$i] = "$across[$i]. $across_list[$i]";
            #print "rsm ======================== $across_list[$i]\n";
    } else {
        $across_list[$i] = "$across[$i]. $across_list[$i]";
    }

}
unshift(@across_list, "::::::: ACROSS :::::::");

$length = @down_list;
for (my $i = 0; $i < $length; $i++) {
    if ($down[$i] < 10) {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
            #print "rsm ======================== $down_list[$i]\n";
    } else {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
}
unshift(@down_list, "::::::: DOWN :::::::");
#put a gap between the acrosses and the downs
unshift(@down_list, "          ");

##### the two lists are now complete .... 
# and have headers on top
#print "\n\n:::::::::::::: COMPLETE ::::::::::::::::\n";
#print join( "\n", @across_list), "\n";
#print join("\n", @down_list), "\n";

if (0) {            
#print "\n::::::::::::::: MATRIX :::::::::::::::\n";
my $count        = 0;
my $grey_squares = 0;
for ( my $i = 1; $i < $height; $i++ ) {
    for ( my $j = 1; $j < $width; $j++ ) {
        print $matrix[$i][$j];
        if ( $matrix[$i][$j] eq 'y' ) {
            $count++;
        }
        if ( $matrix[$i][$j] eq '.' ) {
            $grey_squares++;
        }
    }
    print "\n";
}
print "\nNumbered clue squares == $count\n";
print "Squares greyed out == $grey_squares\n\n";

#-------------------------------------------------

}


#generate_page( $width, \@matrix );

#process the clues ...
#this should cut and wrap the lines
#and set the maximum font size
my ($fontsize, @col1, @col2, @col3, @col4) = process_clues(\@across_list, \@down_list);
exit(0);
#now generate the actual page
print "Calling generate_pdf\n";
generate_pdf($width, \@matrix, \@across_list, \@down_list);

#print "DONE\n";

__END__

        my $w = int($txt->advancewidth($clue));
        if ($w > 125) {
            my @words = split/ /, $clue;
            my $l = @words;
            print "LONG CLUE\n";
            print $clue, "\n";
            for (my $i = 0; $i < $l; $i++) {
                
            }
        }
        $txt->translate($st_x, $st_y);
        $txt->text($clue);
        #print $clue, "\n";
        #print int($txt->advancewidth($clue)), "\n";
        $st_y -= 12;
        
        
        
        
        
        
        
        

sub generate_page {
    print "start generate page\n";
    my $width   = shift;
    #$width--;
    my $sq_size = 405 / $width;

    my $matrix_ref = shift;

    my $output = 'zzzz.ps';
    unlink $output;
    open my $FH, q{>}, $output or die "$0: unable to open the file ($output): $!\n";

    # 171,576 is the upper left corner of the puzzle grid
    my $x_ps = 171;
    my $y_ps = 576;

    print {$FH} "%!\n";
    print {$FH} "/Helvetica findfont 8 scalefont setfont\n";
    my $x = 171;
    my $y = 441;

    print "loop\n";
##LOOP
    my $count = 0;
    for ( my $i = 1; $i < $width; $i++ ) {
        for ( my $j = 1; $j < $width; $j++ ) {
            print {$FH} "newpath\n";
            print {$FH} "$x $y moveto\n";
            print {$FH} "$sq_size 0 rlineto\n";
            print {$FH} "0 -$sq_size rlineto\n";
            print {$FH} "-$sq_size 0 rlineto\n";
            print {$FH} "0 $sq_size rlineto\n";
            print {$FH} "0 setgray\n";
            print {$FH} ".5 setlinewidth\n";
            print {$FH} "closepath\n";

            #if this is a word start ....
            #put the number in the square
            if ( $matrix_ref->[$i][$j] eq 'y' ) {
                $count++;
                my $new_x = $x + 1;
                my $new_y = $y - 7;
                print {$FH} "gsave\n";
                print {$FH} "$new_x $new_y moveto\n";
                print {$FH} "($count) show\n";
                print {$FH} "grestore\n";
            }

            #if this is a blank . . .
            if ( $matrix_ref->[$i][$j] eq '.' ) {
                print {$FH} "gsave\n";
                print {$FH} ".8 setgray\n";
                print {$FH} "fill\n";
                print {$FH} "grestore\n";
            }
            print {$FH} "stroke\n";

            $x += $sq_size;
        }
        $x = 171;
        $y -= $sq_size;
    }
##LOOP

    print "drop shadow\n";
    ##drop shadow bottom
    print {$FH} "newpath\n";
    print {$FH} "176 33 moveto\n";
    print {$FH} "404.5 0 rlineto\n";
    print {$FH} "5 setlinewidth\n";
    print {$FH} ".8 setgray\n";
    print {$FH} "stroke\n";

    ##drop shadow side
    print {$FH} "newpath\n";
    print {$FH} "578.5 35 moveto\n";
    print {$FH} "0 400 rlineto\n";
    print {$FH} "4.1 setlinewidth\n";
    print {$FH} ".8 setgray\n";
    print {$FH} "stroke\n";

    print {$FH} "showpage\n";
    close $FH;

    ## printing . . .
    #print, then unlink the postscript file
    #my $cmd = "lpr -P hp $output";
    #warn "$0: \$cmd == $cmd\n" if $DEBUG == 0;
    #system $cmd;
    #unlink $output;
    print "GENERATED\n";
}

