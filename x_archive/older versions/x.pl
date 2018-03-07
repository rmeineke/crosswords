#!/usr/bin/perl

use Carp;
use warnings;
use strict;
use POSIX;
use PDF::API2;

use Benchmark;

my $DEBUG = 1;
my $SOLVE = 0;

sub carve_up_long_string {

    #print "carve_up_long_string() called\n";
    #this is the entire clue payload
    #dumped into one long string
    my $str = shift;

    #print $str, "\n";

    #passed in the day in case it was
    #sunday ... to save some cycles thru
    #the font processing
    my $day = shift;

    #1620
    #1920
    my $max_height = 1620;
    if ( $day eq 'Sunday' ) {
        $max_height = 1920;
    }

    #print "max_height == $max_height\n";

    #replace any dashes w/ '-|'
    $str =~ s/-/-|/g;

    #replace any slashes w/ '/|'
    $str =~ s/\//\/|/g;

    #now the words are broken out into an array
    #spiltting on the pipe character and the space
    #this should retain any hyphens and slashes
    my @words = split /[| +]/, $str;
    my $pdf   = PDF::API2->new();
    my $page  = $pdf->page;
    my %font
        = (
        Times => { Roman => $pdf->corefont( 'Times', -encoding => 'latin1' ) }
        );

    my $txt = $page->text;
    my @temp_words;
    my $str_font = 14;
    if ( $day eq 'Sunday' ) {
        $str_font = 10;
    }

    #print "str_font = $str_font\n";

    my $end_font;
    my $height = 0;

    #process the strings through each font size
    for ( my $i = $str_font; $i > 6; $i-- ) {

        #print "Checking font size: $i\n";
        #set the font
        $txt->font( $font{'Times'}{'Roman'}, $i );

        #reset the temp array
        @temp_words = ();

        my $temp_str = q{};

        my $num_words = @words;

        #print $num_words, " == num_words\n";

        #while the length is still less than one column wide (125pts)
        #add the next word to the end and test again
        my $str;

        for ( my $i = 0; $i < $num_words; $i++ ) {

            #if the next 'word' is just the clue number
            #the last string needs to be pushed onto
            #the stack
            if ( $words[$i] =~ m/\d+\./ and $i != 0 ) {
                push( @temp_words, $temp_str );
                $temp_str = q{};
            }

            $str      = $temp_str;
            $temp_str = $temp_str . q { } . $words[$i];
            $temp_str =~ s/^\s//;
            $temp_str =~ s/- /-/;
            $temp_str =~ s/\/ /\//;
            $temp_str =~ s/-and/- and/;

            print $temp_str, ".................\n";
            if ( $temp_str =~ m/DOWN/ ) {
                push( @temp_words, q{[[BLANK]]} );
            }
            $temp_str =~ s/999\. //;

            #print $temp_str, "\n";
            print int( $txt->advancewidth($temp_str) ), " -- >>", $temp_str, "<<\n";
            my $new_temp_str = q{      } . $temp_str;
            if ( int( $txt->advancewidth($new_temp_str) ) > 125 ) {
                #print "\n", int( $txt->advancewidth($new_temp_str) ) > 125, "\n";
                #print $new_temp_str, "\n";
                $i--;
                push( @temp_words, $str );
                $temp_str = q{};
            }
        }
        push( @temp_words, $temp_str );

        #that should be the end of the clues
        #all pushed on the stack

        my $num_strings = @temp_words;

        #print $num_strings, " ........ num_strings\n";
        $height = ( $num_strings * ( $i + 2 ) );

        #print $height, " <<<<<<<<<<<<<<<<<<<<<<< \n";
        if ( $height < $max_height ) {
            $end_font = $i;
            last;
        }
    }
    $pdf->end;
    return ( $end_font, $height, @temp_words );
}

###########################
###########################
######################## file
my $start_time = Benchmark->new;
if ( $#ARGV != 0 ) {
    print "Usage:\tx.pl filename\n";
    print "\tx.pl Aug2613.puz\n\n";
    exit(0);
}

my $file = $ARGV[0];

if ( !-e $file ) {
    print "file ($file) not found\n";
    exit(0);
}

my $file_in = $file;
$file_in =~ m/(.*)\.puz/;
my $file_out = $1 . '.pdf';
unlink($file_out);

#print $file_out, "\n";

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
print $width,  " == width\n";
print $height, " == height\n";
my $characters = $width * $height;

print "Num characters == $characters\n";

read $IN, $buffer, 2;

my $num_clues = ord $buffer;

print "Num clues == $num_clues\n";

#skip next 4
read $IN, $buffer, 4;

#read past the solution string
read $IN, $buffer, $characters;
my $solution = $buffer;
print $buffer, "\n";

#lay the solution string out in a matrix
my @matrix;

#add an extra row/column ....
$width++;
$height++;

print $width . " x " . $height . "\n";

#Sept 17, 2013 grid was not square
#so this broke...
#
#it is 16 wide by 15 high
#
#lay some dots around the top and left
for ( my $i = 0; $i < $height; $i++ ) {
    $matrix[$i][0] = '.';

    #$matrix[0][$i] = '.';
}

for ( my $i = 0; $i < $width; $i++ ) {

    #$matrix[$i][0] = '.';
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
my $str_count = 0;
while ( my $bytesRead = ( read $IN, $buffer, 1 )
    and ( $str_count < ( $num_clues + 4 ) ) )
{
    $str .= $buffer;

    if ( $buffer eq "\0" ) {
        push @strings, $str;
        $str_count++;

        #print $str_count, "..... $str\n";
        $str = '';

    }
}

my $title = shift @strings;

#print $title, "\n";

my $day = '?';
if ( $title =~ m/sunday/ixms ) {

    #print "This is a sunday puzzle\n";
    $day = 'Sunday';
}

my $author = shift @strings;

#print $author, "\n";
my $copyright = shift @strings;

#print $copyright, "\n\n";

my $num_strings = @strings;

print "Num clue strings == $num_strings\n";

#the last string provided is a 'note'
#if any
my $note = q{};
if ( $num_strings - $num_clues ) {
    $note = pop(@strings);

    #chop off the terminating null char
    chop($note);
}

#check to see if there is anything left to read
if ( length($note) ) {
    print length($note), "\n";
    print ">>>>>>>>>>>>>>>>$note<<<<<<<<<<<<<<\n";
}

#that should be the last of the strings.

close $IN;

# if their is a section of extra info it should be here
#
# gext
#
# 4 bytes title .... looking for gext
# 2 byte length
# 2 byte checksum
#
# length long data string ....
#
# 0x80 means the square is circled

#re-read the file for circle info
open $IN, '<', $file_in or croak;

my %circles;
$str = 'rsm1';
print "ABOUT to look for some circles......\n";
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {

    substr( $str, 0, 1 ) = substr( $str, 1, 1 );
    substr( $str, 1, 1 ) = substr( $str, 2, 1 );
    substr( $str, 2, 1 ) = substr( $str, 3, 1 );
    substr( $str, 3, 1 ) = $buffer;

    #print $str, "--------------------\n";
    if ( $str eq 'GEXT' ) {
        print "found gext .... $str\n";

        #grab length of the data
        read $IN, $buffer, 2;
        my $l = ord $buffer;

        #print $l, " length\n";

        #blow past checksum
        read $IN, $buffer, 2;

        for ( my $i = 0; $i < $l; $i++ ) {
            read $IN, $buffer, 1;

            if ( substr( unpack( 'B8', $buffer ), 0, 1 ) eq '1' ) {

                #print "$i -- circle\n";
                $circles{$i} = 1;
            }

        }
    }
}

#we are done w/ the input
close $IN;

#------------------------------------------------------

#re-read the file for REBUS info
open $IN, '<', $file_in or croak;
my %rebus;
$str = 'rsm1';
print "ABOUT to look for some REBUS info ......\n";
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {

    substr( $str, 0, 1 ) = substr( $str, 1, 1 );
    substr( $str, 1, 1 ) = substr( $str, 2, 1 );
    substr( $str, 2, 1 ) = substr( $str, 3, 1 );
    substr( $str, 3, 1 ) = $buffer;

    #print $str, "--------------------\n";
    if ( $str eq 'GRBS' ) {
        print "found GRBS .... $str\n";

        #grab length of the data
        read $IN, $buffer, 2;
        my $l = ord $buffer;
        print $l, " length\n";

        #blow past checksum
        read $IN, $buffer, 2;

        for ( my $i = 0; $i < $l; $i++ ) {
            read $IN, $buffer, 1;

            #print $buffer, "\n";
            if ( ord $buffer > 0 ) {
                $rebus{$i} = 1;
            }

        }
    }
}

#we are done w/ the input
close $IN;

#-----------------------------------------------------



#re-read the file for circle info
open $IN, '<', $file_in or croak;
$str = 'rsm1';
print "ABOUT to look for some RTBL info ......\n";
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {

    substr( $str, 0, 1 ) = substr( $str, 1, 1 );
    substr( $str, 1, 1 ) = substr( $str, 2, 1 );
    substr( $str, 2, 1 ) = substr( $str, 3, 1 );
    substr( $str, 3, 1 ) = $buffer;

    #print $str, "--------------------\n";
    if ( $str eq 'RTBL' ) {
        print "found RTBL .... $str\n";

        #grab length of the data
        read $IN, $buffer, 2;
        my $l = ord $buffer;
        print $l, " length\n";

        #blow past checksum
        read $IN, $buffer, 2;

        for ( my $i = 0; $i < $l; $i++ ) {
            read $IN, $buffer, 1;
            print $buffer, "\n";
        }
    }
}

#we are done w/ the input
close $IN;

#tweaking the clue matrix here
#
#this will change any dashes to the letter 'y'
#if they will need to be numbered

#print $width, " == width\n";
#print $height, " == height\n";
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
        next if $matrix[$i][$j] eq '.';
        if ( $i == 1 || $matrix[ ( $i - 1 ) ][$j] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }    #if
    }    #for
}    #for

#print $width, " == width\n";
#print $height, " == height\n";
for ( my $j = 0; $j < $width; $j++ ) {
    for ( my $i = 0; $i < $height; $i++ ) {
        next if ( $matrix[$i][$j] eq '.' || $matrix[$i][$j] eq 'y' );
        if ( $j == 1 || $matrix[$i][ ( $j - 1 ) ] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }    #if
    }    #for
}    #for

#here is a weird edge case
#august 29 2013
#had a blank square in the middle of it
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < ( $width - 1 ); $j++ ) {
        next if $matrix[$i][$j] eq '.';

        #Sprint $i . ' - ' . $j, "\n";
        if (   $matrix[ ( $i - 1 ) ][$j] eq '.'
            && $matrix[$i][ ( $j + 1 ) ] eq '.'
            && $matrix[ ( $i + 1 ) ][$j] eq '.'
            && $matrix[$i][ ( $j - 1 ) ] eq '.' )
        {
            $matrix[$i][$j] = 'X';
        }    #if
    }    #for
}    #for

if (0) {
    for ( my $i = 1; $i < $height; $i++ ) {
        for ( my $j = 1; $j < $width; $j++ ) {
            print $matrix[$i][$j];
        }
        print "\n";
    }
}

if (0) {
    print "\n\n\n";
    for ( my $i = 0; $i < $height; $i++ ) {
        for ( my $j = 0; $j < $width; $j++ ) {
            print $matrix[$i][$j];
        }
        print "\n";
    }
    print "\n\n\n";
}

#count the clues across
my $num_across = 0;
my $num_down   = 0;
my $clue_count = 0;
my @clue_order;
my $numbered = 0;

my @across;
my @down;

#parse the clues and then separate them into across and down
#print $height, " == height\n";
#print $width, " == width\n";
for ( my $i = 1; $i < $height; $i++ ) {
    for ( my $j = 1; $j < $width; $j++ ) {
        next if $matrix[$i][$j] eq '.';

        my $a = 0;
        my $d = 0;

        #any position and preceded by a dot (.)
        if ( $matrix[$i][$j] eq 'y' && $matrix[$i][ ( $j - 1 ) ] eq '.' ) {
            $num_across++;
            $a++;
            push( @clue_order, 'a' );
        }    #if

        if ( $matrix[$i][$j] eq 'y' && $matrix[ ( $i - 1 ) ][$j] eq '.' ) {
            $num_down++;
            $d++;
            push( @clue_order, 'd' );
        }    #if

        #set up the individual across and down lists
        if ( $a || $d ) {
            $clue_count++;
            if ($a) {
                push( @across, $clue_count );
            }
            if ($d) {
                push( @down, $clue_count );
            }
        }    #if
    }    #for
}    #for

if (1) {
    print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
    print join( ',', @across );
    print "\n\n";
    print "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n";
    print join( ',', @down );
    print "\n\n";
}

$num_across = @across;
$num_down   = @down;
print $num_across, " == num_across\n";
print $num_down,   " == num_down\n";
my $ttl_clues = $num_across + $num_down;
print $ttl_clues, " == ttl_clues\n\n";

my $three_digit_across = 0;
my $three_digit_down   = 0;

if ( $across[ $num_across - 1 ] > 99 ) {

    #print "There are triple digit ACROSS clues in this puzzle\n";
    $three_digit_across++;
}

if ( $down[ $num_down - 1 ] > 99 ) {

    #print "There are triple digit DOWN clues in this puzzle\n";
    $three_digit_down++;
}

my @across_list;
my @down_list;
foreach my $dir (@clue_order) {
    my $clue = shift(@strings);
    if ( $dir eq 'a' ) {
        push( @across_list, $clue );
    }
    else {
        push( @down_list, $clue );
    }
}

#######################3rsm
# this is to line up the single
# number clues with the double letter clues
#
my $length = @across_list;
for ( my $i = 0; $i < $length; $i++ ) {
    if ( $across[$i] < 10 ) {
        $across_list[$i] = "$across[$i]. $across_list[$i]";
    }
    else {
        $across_list[$i] = "$across[$i]. $across_list[$i]";
    }

}
unshift( @across_list, "999. ::ACROSS:::::::" );

$length = @down_list;
for ( my $i = 0; $i < $length; $i++ ) {
    if ( $down[$i] < 10 ) {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
    else {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
}
unshift( @down_list, "999. ::DOWN:::::::" );

#put a gap between the acrosses and the downs
unshift( @down_list, "          " );

my @clue_list = ( @across_list, @down_list );
if (0) {
    foreach my $c (@clue_list) {
        print $c, "\n";
    }
}

my $long_str = q{};
foreach my $c (@clue_list) {
    my @words = split / +/, $c;
    foreach my $w (@words) {
        $long_str = $long_str . q{ } . $w;
    }
}

$long_str =~ s/^\s+//;

#print $long_str, "\n";

my ( $font_size, $ttl_height, @shortened_clue_list )
    = carve_up_long_string( $long_str, $day );



if (1) {
    for my $w (@shortened_clue_list) {
        print ">>>>>", $w, "<<<<<\n";
    }
}
#print $ttl_height, " == ttl_height\n";
my $col_height = ceil( ( $ttl_height - 720 ) / 3 );

#print $col_height, " == 2nd/3rd/4th\n";

#print '$day == ' . $day . "\n";
#print "\n$font_size\n\n";
my $proper_font_size = $font_size;
if (1) {
    for my $w (@shortened_clue_list) {
        print $w, "\n";
    }
}
#this makes the grid_size dynamic
my $grid_font = 8;
my $grid_size = ceil( 720 - $col_height );
if ( $grid_size > 405 ) {
    $grid_size = 405;
}
if ( $grid_size < 400 ) {
    $grid_font = 6;
}

#print $grid_size, " == grid_size\n";
#print $grid_font, " == grid_font\n";

#my ( $proper_font_size, @final_clue_list ) = get_font_size( \@clue_list, $day );

#print $proper_font_size, " <----- font\n";
my $lines = @shortened_clue_list;

#print $lines, " lines in clue list\n";

my $line_spacing = 2;
my $first_col = ceil( 720 / ( $proper_font_size + $line_spacing ) );

if ( $shortened_clue_list[ $first_col - 1 ] eq '::DOWN:::::::' ) {
    $first_col--;
}

$lines = $lines - $first_col;
my $second_col = ceil( $lines / 3 );

$lines = $lines - $second_col;

my $third_col = ceil( $lines / 2 );

my $fourth_col = $lines - $third_col;

my $check = $first_col + $second_col + $third_col + $fourth_col;

#print $first_col,  " 1st\n";
#print $second_col, " 2nd \n";
#print $third_col,  " 3rd\n";
#print $fourth_col, " 4th\n";

#print "-------------\n";
#print $check, "\n";

##############################################
# start to assemble the various parts of the
# pdf output
my $pdf = PDF::API2->new( -file => "$file_out" );
my $page = $pdf->page;

#print grey columns behind the clues for
#debugging purposes
if (0) {
    my $box = $page->gfx;
    $box->fillcolor('#dddddd');
    $box->rect( 36, 36, 125, 720 );
    $box->fill();

    $box->rect( 171, 456, 125, 300 );
    $box->fill();

    $box->rect( 306, 456, 125, 300 );
    $box->fill();

    $box->rect( 441, ( 456 - 36 ), 125, ($col_height) );
    $box->fill();
}

my %font = (
    Times => {
        Bold  => $pdf->corefont( 'Times-Bold', -encoding => 'latin1' ),
        Roman => $pdf->corefont( 'Times',      -encoding => 'latin1' )
    }
);
my $txt = $page->text;
$txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
$txt->fillcolor('#000000');

my @columns = ( $first_col, $second_col, $third_col, $fourth_col );
my @first_lines = (
    0, $first_col,
    $first_col + $second_col,
    $first_col + $second_col + $third_col
);

my @col_x = ( 36,  171, 306, 441 );
my @col_y = ( 756, 756, 756, 756 );
for ( my $col = 0; $col < 4; $col++ ) {

    #print "$col -- $columns[$col] -- $col_x[$col] -- $col_y[$col]\n";

    my $st_x = $col_x[$col];
    my $st_y = $col_y[$col];
    $txt->translate( $st_x, $st_y );

    my $first_line = $first_lines[$col];
    my $last_line  = $first_line + $columns[$col];
    my $top_line   = 1;

    for ( my $i = $first_line; $i < $last_line; $i++ ) {

        #set proper font_size;
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');

        my $output = $shortened_clue_list[$i];

        if ( $top_line == 1 and $output =~ m/BLANK/ ) {
            $last_line++;
            $first_lines[2]++;
            $first_lines[3]++;
            $columns[2]--;
            $columns[3]--;
            next;
        }

        if ($three_digit_across) {

            #no digits -- line continuation
            if ( $output !~ m/\d+\./ ) {
                $output = q{        } . $output;
            }

            #single digit clue
            if ( $output =~ m/^\d\.\s/ ) {
                $output = q{    } . $output;
            }

            #double digit clue
            if ( $output =~ m/^\d\d\.\s/ ) {
                $output = q{  } . $output;

            }

            if ( $output =~ m/[[BLANK]]/ ) {
                $output = q{  };
            }

            if ( $output =~ m/ACROSS/ ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::ACROSS:::::::';
            }

            if ( $output =~ m/DOWN/ ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::DOWN:::::::';
            }

        }
        else {

            #continuation line
            if ( $output !~ m/\d+\./ ) {
                $output = q{      } . $output;
            }

            #single digit clues
            if ( $output =~ m/^\d\.\s/ ) {
                $output = q{  } . $output;
            }

            if ( $output =~ m/[[BLANK]]/ ) {
                $output = q{  };
            }

            if ( $output =~ m/ACROSS/ ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::ACROSS:::::::';
            }

            if ( $output =~ m/DOWN/ ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::DOWN:::::::';
            }

        }
        $txt->text($output);
        $st_y = $st_y - $proper_font_size - 2;
        $txt->translate( $st_x, $st_y );

        $top_line = 0;

    }    #for
}

##########################
#Draw the box here .....
#print $width, " width\n";
#
#this next line screwed things up
#when the grid was not a perfect square!
#$height = $width;

my $sq_size = int( $grid_size / ( $width - 1 ) );
print $sq_size, " sq size\n";

my $box_size_width  = $sq_size * ( $width - 1 );
my $box_size_height = $sq_size * ( $height - 1 );
print $box_size_width,  " == box_size_width\n";
print $box_size_height, " == box_size_height\n";

#print $box_size, " box_size\n\n";
my $box_size_difference = $grid_size - $box_size_width;
if ( $sq_size < 20 ) {
    $grid_font = 6;
}

#this is the lower, right-hand corner
my $reference_corner_x = 576;
my $reference_corner_y = 36;

#this should put us at the upper, left-hand
#corner of the largest box possible.
my $box_upper_left_x = $reference_corner_x - $box_size_width;
my $box_upper_left_y = $reference_corner_y + $box_size_height;
print $box_upper_left_x, " == box_upper_left_x\n";
print $box_upper_left_y, " == box_upper_left_y\n";

my $box = $page->gfx;
$box->fillcolor('#aaaaaa');

#my $height = $width;
my $count = 0;
my $x;
my $y;
my $st_x;
my $st_y;

#start the text .........
$txt = $page->text;
$txt->font( $font{'Times'}{'Roman'}, $grid_font );
$txt->fillcolor('#000000');

#fill the gray boxes....
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
my $circle_cnt = 0;
print "\n";
for ( my $i = 0; $i < $height - 1; $i++ ) {
    $y = $st_y - ( ( $i + 1 ) * $sq_size );
    for ( my $j = 0; $j < $width - 1; $j++ ) {

        #print "$i .. $j\n";

        $x = $st_x + ( $j * $sq_size );
        if ( $matrix[ $i + 1 ][ $j + 1 ] eq '.' ) {
            $box->rect( $x, $y, $sq_size, $sq_size );
            $box->fill;
        }
    }
}

########################
# numbers for the boxes

$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
for ( my $i = 0; $i < $height - 1; $i++ ) {

    #print "$x x $y ..........\n";
    $y = $st_y - ( ($i) * $sq_size );
    for ( my $j = 0; $j < $width - 1; $j++ ) {
        $x = $st_x + ( $j * $sq_size );
        if ( $matrix[ $i + 1 ][ $j + 1 ] eq 'y' ) {
            $count++;
            $txt->translate( ( $x + 1 ), ( $y - $grid_font ) );
            $txt->text("$count");
        }
    }
}

#set up the line for grid drawing
my $line = $page->gfx;
$line->linewidth(.5);
$line->strokecolor('#000000');

#upperleft of the grid
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
$line->move( $st_x, $st_y );
$width--;

#horizontal
for ( my $i = -1; $i < $height - 1; $i++ ) {
    $line->line( $st_x + $box_size_width, $st_y );
    $line->stroke;

    $st_y -= $sq_size;
    $line->move( $st_x, $st_y );
}

#vertical
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
$line->move( $st_x, $st_y );

for ( my $i = -1; $i < $width; $i++ ) {
    $line->line( $st_x, $st_y - $box_size_height );
    $line->stroke;

    $st_x += $sq_size;
    $line->move( $st_x, $st_y );
}

my $txt2 = $page->text;
$txt2->font( $font{'Times'}{'Bold'}, 8 );
$txt2->fillcolor('#000000');

$title = $title . "    [$proper_font_size]";
my $l = int( $txt2->advancewidth($title) );

#$txt2->translate( (578 - $l - $box_size_difference), $reference_corner_y - 10 + $box_size_difference );

$txt2->translate( $reference_corner_x - $l, $reference_corner_y - 10 );
$txt2->text($title);

#$note = "XXXXXXXXXXXXX";
if ( $note ne '' ) {
    my $note_x = $box_upper_left_x;
    my $note_y = $box_upper_left_y;

    $txt->translate( $note_x, ( $note_y + 2 ) );
    $txt->font( $font{'Times'}{'Bold'}, 8 );
    $txt->text($note);
}

$height--;

#are there any circles to draw?
if (%circles) {
    
    
    my $circle = $page->gfx;
    $circle->strokecolor('#ff0000');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    print "$x .. $y <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
    my $circle_cnt = -1;

    print "$width x $height >>>>>>>>>>>>>>>>>>>>>\n";
    for ( my $i = 0; $i < $height; $i++ ) {
        for ( my $j = 0; $j < $width; $j++ ) {
            $circle_cnt++;

            #print "$i x $j\n";
            if ( $circles{$circle_cnt} ) {

                #print "$circle_cnt ... gets a circle ... $x .. $y   ----- $i x $j\n";
                $circle->circle(
                    $x + ( $sq_size / 2 ),
                    $y - ( $sq_size / 2 ),
                    ( ( $sq_size / 2 ) - 1 )
                );
                $circle->stroke;
            }
            $x += $sq_size;
        }

        #print "$i ... reset \$x ... $x\n";
        $x = $box_upper_left_x;

        #print "$i ... reset \$x ... $x\n";

        $y -= $sq_size;
    }
}




#are there any REBUS to draw?
if (%rebus) {
    
    my $txt = $page->text;
    my $eg_trans = $pdf->egstate();
    $eg_trans->transparency(0.9);
    $txt->font( $font{'Times'}{'Roman'}, $sq_size);
    $txt->egstate($eg_trans);
    $txt->fillcolor('#0000ff');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    print "$x .. $y <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n";
    my $rebus_cnt = -1;

    print "$width x $height >>>>>>>>>>>>>>>>>>>>>\n";
    for ( my $i = 0; $i < $height; $i++ ) {
        for ( my $j = 0; $j < $width; $j++ ) {
            $rebus_cnt++;

            #print "$i x $j\n";
            if ( $rebus{$rebus_cnt} ) {
                $txt->translate( $x + ( .25 * $sq_size ), $y - ( $sq_size ));
                $txt->text('*');
            }
            $x += $sq_size;
        }

        print "$i ... reset \$x ... $x\n";
        $x = $box_upper_left_x;

        #print "$i ... reset \$x ... $x\n";

        $y -= $sq_size;
    }
}






# SOLUTION
if ($SOLVE) {
    my $txt = $page->text;
    my $font_size = ceil($sq_size) - 4;
    
    print $font_size, " == font_size .... solution\n";
    
    my $eg_trans = $pdf->egstate();
    $eg_trans->transparency(0.2);
    $txt->egstate($eg_trans);
    
    $txt->font( $font{'Times'}{'Roman'}, $font_size);
    $txt->fillcolor('#000000');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    my $char_cnt = -1;

    for ( my $i = 0; $i < $height; $i++ ) {
        for ( my $j = 0; $j < $width; $j++ ) {
            $char_cnt++;
            #$txt->translate( $x + ( .25 * $sq_size ) - 2 , $y - ( $sq_size ) + 2);

            my $char = substr $solution, $char_cnt, 1;
            $txt->translate( $x + ($sq_size / 2), $y - ($sq_size / 2) - ($font_size / 2) + 2 );
            if ($char ne '.') {
                $txt->text_center($char);
            }
            $x += $sq_size;
        }
        $x = $box_upper_left_x;
        $y -= $sq_size;
    }
}

$pdf->save;
$pdf->end();

my $end_time = Benchmark->new;
my $timer_diff = timediff( $end_time, $start_time );
print timestr( $timer_diff, 'all' );
print "\n\n";
__END__
