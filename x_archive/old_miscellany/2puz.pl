#!/usr/bin/perl

use Carp;
use warnings;
use strict;

sub generate_page {
    print "start generate page\n";
    my $width   = shift;
    my $sq_size = 405 / $width;

    my $matrix_ref = shift;

    #print "**\n";
    #print $matrix_ref->[1][2], "\n";
    #print "**\n";

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
    for ( my $i = 0; $i < $width; $i++ ) {
        for ( my $j = 0; $j < $width; $j++ ) {
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
print $width . " x " . $height . "\n";

my $characters = $width * $height;
print "Num characters == $characters\n";

read $IN, $buffer, 2;

my $num_clues = ord $buffer;
print "Num clues == $num_clues\n";

#skip next 4
read $IN, $buffer, 4;

#read in the solution string
read $IN, $buffer, $characters;
print "::::::::::::::::::::::::::::::::::\n";
print "$buffer\n";
print "::::::::::::::::::::::::::::::::::\n";

#lay the solution string out in a matrix
my @matrix;
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
        read $IN, $buffer, 1;
        my $str = $buffer;
        $matrix[$i][$j] = $str;
    }
}


my $l = @matrix;
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
        next if $matrix[$i][$j] eq '.';
        if ( $i == 0 || $matrix[ ( $i - 1 ) ][$j] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }
    }
}

for ( my $j = 0; $j < $width; $j++ ) {
    for ( my $i = 0; $i < $height; $i++ ) {
        next if ( $matrix[$i][$j] eq '.' || $matrix[$i][$j] eq 'y' );
        if ( $j == 0 || $matrix[$i][ ( $j - 1 ) ] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }
    }
}

#count the clues across
my $num_across = 0;
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {

        #first position and a letter ...
        if ( $i == 0 && $matrix[$i][$j] eq 'y' ) {

            #$num_across++;
        }

        #any other position and preceded by a dot (.)
        if ( $matrix[$i][$j] eq 'y' && $matrix[$i][ ( $j - 1 ) ] eq '.' ) {

            #print $matrix[$i][$j - 1], $matrix[$i][$j], "\n";
            $num_across++;
        }
    }
}
print "\n\nnum_across == $num_across\n\n";

#try the downs
my $down = 0;
for ( my $j = 0; $j < $width; $j++ ) {
    for ( my $i = 0; $i < $height; $i++ ) {
        if ( $j == 0 && $matrix[$i][$j] eq 'y' ) {
            $down++;
        }
        if ( $matrix[$i][$j] eq 'y' && $matrix[ $i - 1 ][$j] eq '-' ) {
            $down++;
        }
    }
}
print "+++++++++ $down\n";

print "\nMATRIX:::\n";
my $count        = 0;
my $grey_squares = 0;
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
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



#try to determine order of clues 
my @clue_order;

for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
        if ($matrix[$i][$j] eq 'y') {
            print "clue\n";
            print "$i, $j -- $matrix[$i][$j]\n";
        }
    }
}
#-------------------------------------------------

#collect the clues into the @strings array
my $str = '';
my @strings;
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {
    $str .= $buffer;
    
    if ( $buffer eq "\0" ) {
        push @strings, $str;
        #print "..... $str\n";
        $str = '';
    }
}
$l = @strings;
print "Total number of strings == $l\n";

#we are done w/ the input
close $IN;

my $title = shift @strings;
print $title, "\n";
my $author = shift @strings;
print $author, "\n";
my $copyright = shift @strings;
print $copyright, "\n\n";

my $num_strings = @strings;
print "Num clue strings == $num_strings\n";

#something about a blank string to start
#pop it off the stack and move on.
#
#Is this the theme or title ????
if ( $strings[ $num_strings - 1 ] eq "\0" ) {
    #print "__$strings[$num_strings - 1]__\n";
    #pop @strings;
}

$num_strings = @strings;
print "Num strings == $num_strings\n";

#print "__$strings[$num_strings - 1]__\n";

#print out the clues ...
for ( my $i = 0; $i < $num_strings; $i++ ) {
    #print $i, " -- ", $strings[$i], "\n";
}

print "Generate page\n";
generate_page( $width, \@matrix );
print "DONE\n";
