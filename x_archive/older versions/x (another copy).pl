#!/usr/bin/perl

use Carp;
use warnings;
use strict;
use POSIX;
use PDF::API2;

use Benchmark;

sub carve_up_long_string {
    print "carve_up_long_string() called\n";
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
    if ($day eq 'Sunday') {
        $max_height = 1920;        
    }
    print "max_height == $max_height\n";
    
    #replace any dashes w/ '-|'
    $str =~ s/-/-|/g;
    #replace any slashes w/ '/|'
    $str =~ s/\//\/|/g;
    
    #now the words are broken out into an array
    #spiltting on the pipe character and the space
    #this should retain any hyphens and slashes
    my @words = split /[| +]/, $str;
    my $pdf = PDF::API2->new();
    my $page = $pdf->page;
    my %font
        = (
        Times => { Roman => $pdf->corefont( 'Times', -encoding => 'latin1' ) }
        );

    my $txt = $page->text;
    my @temp_words;
    my $str_font = 14;
    if ($day eq 'Sunday') {
        $str_font = 10;
    }
    print "str_font = $str_font\n";
    
    my $end_font;
    my $height = 0;
    #process the strings through each font size
    for (my $i = $str_font; $i > 6; $i--) {
        print "Checking font size: $i\n";
        #set the font
        $txt->font( $font{'Times'}{'Roman'}, $i);
        
        #reset the temp array
        @temp_words = ();
        
        my $temp_str = q{};
        
        my $num_words = @words;
        print $num_words, " == num_words\n";
            
        #while the length is still less than one column wide (125pts)
        #add the next word to the end and test again
        my $str;

        for (my $i = 0; $i < $num_words; $i++) {
            
            #if the next 'word' is just the clue number
            #the last string needs to be pushed onto 
            #the stack
            if ($words[$i] =~ m/\d+\./ and $i != 0) {
                push(@temp_words, $temp_str);
                $temp_str = q{};
            }
            
            $str = $temp_str;
            $temp_str = $temp_str . q { } . $words[$i];
            $temp_str =~ s/^\s//;
            $temp_str =~ s/- /-/;
            #print $temp_str, ".................\n";
            if ($temp_str =~ m/DOWN/) {
                push(@temp_words, q{[[BLANK]]});
            }
            $temp_str =~ s/999\. //;
            #print $temp_str, "\n";
            my $new_temp_str = q{      } . $temp_str;
            if ( int( $txt->advancewidth($new_temp_str) ) > 125 ) {
                $i--;
                push(@temp_words, $str);
                $temp_str = q{};
            }
        }
        push(@temp_words, $temp_str);
        #that should be the end of the clues 
        #all pushed on the stack
        
        my $num_strings = @temp_words;
        #print $num_strings, " ........ num_strings\n";
        $height = ($num_strings * ( $i + 2));
        #print $height, " <<<<<<<<<<<<<<<<<<<<<<< \n";
        if ($height < $max_height) {
            $end_font = $i;
            last;
        }
    }
    $pdf->end;
    return ($end_font, $height, @temp_words);    
}


sub XXXget_length {
    my $str = shift;
    my $f   = shift;

    my $pdf = PDF::API2->new();

    my $page = $pdf->page;
    my %font
        = (
        Times => { Roman => $pdf->corefont( 'Times', -encoding => 'latin1' ) }
        );

    my $txt = $page->text;
    $txt->font( $font{'Times'}{'Roman'}, $f );
    my $l = int( $txt->advancewidth($str) );
    $pdf->end;
    return $l;
}

sub XXXsplit_clue {

    my $clue      = shift;
    my $font_size = shift;

    my $pdf = PDF::API2->new();

    my $page = $pdf->page;
    my %font = (Times => {
            Roman  => $pdf->corefont( 'Times',        -encoding => 'latin1' )
        }
    );

    my $txt = $page->text;
    $txt->font( $font{'Times'}{'Roman'}, $font_size );

    #print $clue, "\n";
    #bust the clue up into separate words...
    my @words = split / +/, $clue;

    #print "words == ", ($#words + 1), " -- $clue\n";
    my $l     = 0;
    my $str   = q{};
    my $count = 0;

    while ( $l < 125 ) {
        $str = $str . q{ } . $words[$count];
        $count++;
        $l = int( $txt->advancewidth($str) );
        
        #if it is too long ... and it is the first word....
        if ($l > 125 and $count == 1) {
            print "\n";
            print "This is going to bomb out here:\n";
            print $clue, "\n";
            print $str, "\n";
            
            
            my ($s1, $s2);
            
            #looking for long, hyphenated words here
            # Hammer-on-the-thumb sounds
            if ($str =~ m/(.*)-(.*)/) {
                $s1 = $1 . '-';
                $s2 = '....' . $2;
            }
            
            #this one looks for slashes
            # Actress/screenwriter Kazan
            if ($str =~ m/(.*)\/(.*)/) {
                $s1 = $1 . '/';
                $s2 = '....' . $2;
            }
            
            print "$s1\n";
            print $s2, "\n";
            return ($s1, $s2);
        }
        #print "$l == $str\n";
    }
    
    $count--;
    $str = q{};
    my $skip = 0;
    for ( my $i = 0; $i < $count; $i++ ) {
        if ($skip) {
            $str = $str . q{ } . $words[$i];
        }
        else {
            $str = $str . $words[$i];
        }
        $skip++;
    }

    $skip = 0;
    my $left = q{};
    for ( my $i = $count; $i < ( $#words + 1 ); $i++ ) {
        if ($skip) {
            $left = $left . q{ } . $words[$i];
        }
        else {
            $left = $left . $words[$i];
        }
        $skip++;
    }
    
    my $tmp = $left;
    $tmp = q{....} . $left;
    $l   = int( $txt->advancewidth($tmp) );
    
    print "\n\n";
    print $str, "\n";
    print $tmp, "\n";
    $pdf->end;
    return ( $str, $tmp );
}

sub XXXget_font_size {
    my $pdf_ref = shift;
    my $clues_ref = shift;
    my $day = shift;
    my @strings = @$clues_ref;

    if (0) {
        foreach my $c (@strings) {
            print $c, "\n";
        }
    }
    my $total_height;

    #if $day is Sunday .... let's start w/ a smaller font
    #as a default ... to save processing time.
    my $font = 14;
    if ($day eq 'Sunday') {
        $font = 10;
    }
    for ( my $i = $font; $i > 5; $i-- ) {
        print "entering for loop: font size -- ", $i, "\n";
        my $changes = 1;
        my $iterations = 0;
        while ($changes) {
            $changes = 0;
            my @new_array = ();
            foreach my $s (@strings) {
                $iterations++;
                #print $iterations, " iterations\n";
                if ( get_length( $s, $i ) > 125 ) {
                    #print "chop -- $s\n";
                    my ( $str, $whats_left ) = split_clue( $s, $i );
                    
                    #print $str, ' ***** ', $whats_left, "\n";
                    push( @new_array, $str );
                    push( @new_array, $whats_left );

                    $changes++;
                }
                else {
                    push( @new_array, $s );
                }#if
            }#foreach
            @strings = @new_array;
        }#while


        my $num_clues = @strings;
        print $num_clues, " num_clues\n";
        $total_height = $num_clues * ( $i + 2 );
        print $total_height, " height\n";

        # 720 + 300 + 300 + 300 = 1620
        my $max_height = 1620;
        #if sunday .... 
        # 720 + 400 + 400 + 400 = 1920
        if ($day eq 'Sunday') {
            $max_height = 1920;
        }
        
        if ( $total_height < $max_height ) {
            print "max_height: ", $max_height, "\n";
            print "about to return total_height: ", $total_height, "\n";
            print "about to return font size: ",    $i,            "\n";
            return ( $i, @strings );
        }
        else {
            @strings = @$clues_ref;
        }
    }
}



###########################
###########################
######################## file

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
print $file_out, "\n";

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

#print "Num characters == $characters\n";

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

#print $width . " x " . $height . "\n";

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
my $str_count = 0;
while ( my $bytesRead = ( read $IN, $buffer, 1 ) and ($str_count < ($num_clues + 4)) ) {
    $str .= $buffer;

    if ( $buffer eq "\0" ) {
        push @strings, $str;
        $str_count++;
        #print $str_count, "..... $str\n";
        $str = '';

    }
}


my $title = shift @strings;
print $title, "\n";

my $day = '?';
if ($title =~ m/sunday/ixms) {
    print "This is a sunday puzzle\n";
    $day = 'Sunday';
}

my $author = shift @strings;
print $author, "\n";
my $copyright = shift @strings;
print $copyright, "\n\n";

my $num_strings = @strings;

print "Num clue strings == $num_strings\n";

#the last string provided is a 'note' 
#if any
my $note = q{};
if ($num_strings - $num_clues) {
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
my %circles;
$str = 'rsm1';
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {
    
    substr($str, 0, 1) = substr($str, 1, 1);
    substr($str, 1, 1) = substr($str, 2, 1);
    substr($str, 2, 1) = substr($str, 3, 1);
    substr($str, 3, 1) = $buffer;
    
    if ($str eq 'GEXT') {
        print "found gext .... $str\n";
        
        #grab length of the data    
        read $IN, $buffer, 2;
        my $l = ord $buffer;
        print $l, " length\n";
        
        #blow past checksum
        read $IN, $buffer, 2;
        
        for (my $i = 0; $i < $l; $i++) {
            read $IN, $buffer, 1;
            
            if (substr( unpack('B8', $buffer), 0, 1) eq '1') {
                #print "$i -- circle\n";
                $circles{$i} = 1;
            }
            
        }
    }
}


#we are done w/ the input
close $IN;



#tweaking the clue matrix here
#
#this will change any dashes to the letter 'y'
#if they will need to be numbered
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < $width; $j++ ) {
        next if $matrix[$i][$j] eq '.';
        if ( $i == 1 || $matrix[ ( $i - 1 ) ][$j] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }    #if
    }    #for
}    #for

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
    for ( my $j = 0; $j < ($width - 1); $j++ ) {
        next if $matrix[$i][$j] eq '.';
        
        #Sprint $i . ' - ' . $j, "\n";
        if ( $matrix[ ( $i - 1 ) ][$j] eq '.' && $matrix[$i][($j + 1)] eq '.' && $matrix[($i + 1)][$j] eq '.' && $matrix[$i][($j-1)] eq '.' ) {
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


#count the clues across
my $num_across = 0;
my $num_down   = 0;
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
print join (',', @across);
print "\n\n";
print "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n";
print join (',', @down);
print "\n\n";
}

#my $num_across = @across;
#my $num_down = @down; 
my $three_digit_across = 0;
my $three_digit_down = 0;

if ($across[$num_across - 1] > 99) {
    print "There are triple digit ACROSS clues in this puzzle\n";
    $three_digit_across++;
}

if ($down[$num_down -1] > 99) {
    print "There are triple digit DOWN clues in this puzzle\n";
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
if (1) {
foreach my $c (@clue_list) {
    #print $c, "\n";
}
}



#..........................................
#..........................................
#..........................................
#..........................................
#..........................................
#..........................................

my $long_str = q{};
foreach my $c (@clue_list) {
    my @words = split / +/, $c;
    foreach my $w (@words) {
        $long_str = $long_str . q{ } . $w;
    }
}

$long_str =~ s/^\s+//;
#print $long_str, "\n";

my ($font_size, $ttl_height, @shortened_clue_list) = carve_up_long_string($long_str, $day);
print $ttl_height, " == ttl_height\n";
my $col_height = ceil(($ttl_height - 720) / 3);

print $col_height, " == 2nd/3rd/4th\n";

print '$day == ' . $day . "\n";
print "\n$font_size\n\n";
my $proper_font_size = $font_size;
for my $w (@shortened_clue_list) {
    #print $w, "\n";
}

#this makes the grid_size dynamic
my $grid_font = 8;
my $grid_size = ceil(720 - $col_height);
if ($grid_size > 405) {
    $grid_size = 405;
}
if ($grid_size < 400) {
    $grid_font = 6;
}
print $grid_size, " == grid_size\n";
print $grid_font, " == grid_font\n";

#my ( $proper_font_size, @final_clue_list ) = get_font_size( \@clue_list, $day );




#this did not work out perfeclty /// 
#especially for sunday puzzles which
#might have 3-digit clue numbers
#
#insert an extra space if it is a 
#single-digit clue
if (0) {
    foreach my $c (@shortened_clue_list) {
        if ($c =~ m/^\d\.\ .*/) {
            $c =~ s/\.\ /\.   /;        
        }
    }
}

#print $proper_font_size, " <----- font\n";
my $lines = @shortened_clue_list;
print $lines, " lines in clue list\n";


my $line_spacing = 2;
my $first_col = ceil( 720 / ( $proper_font_size + $line_spacing) );

if ($shortened_clue_list[$first_col - 1] eq '::DOWN:::::::') {
    $first_col--;
}

$lines = $lines - $first_col;
my $second_col = ceil( $lines / 3 );

$lines = $lines - $second_col;

my $third_col  = ceil( $lines / 2);

my $fourth_col = $lines - $third_col;

my $check = $first_col + $second_col + $third_col + $fourth_col;
print $first_col,  " 1st\n";
print $second_col, " 2nd \n";
print $third_col,  " 3rd\n";
print $fourth_col, " 4th\n";

print "-------------\n";
print $check, "\n";


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
$box->rect(36, 36, 125, 720);
$box->fill();

$box->rect(171, 456, 125, 300);
$box->fill();

$box->rect(306, 456, 125, 300);
$box->fill();

$box->rect(441, (456 - 36) , 125, ($col_height));
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


#************************************************
#************************************************
#************************************************
#************************************************
#************************************************
#************************************************
#************************************************

my @columns = ($first_col, $second_col, $third_col, $fourth_col);
my @first_lines = (0, 
                    $first_col, 
                    $first_col + $second_col,  
                    $first_col + $second_col + $third_col);
                    
my @col_x = (36, 171, 306, 441);
my @col_y = (756, 756, 756, 756);
for (my $col = 0; $col < 4; $col++) {
    print "$col -- $columns[$col] -- $col_x[$col] -- $col_y[$col]\n";
    
    my $st_x = $col_x[$col];
    my $st_y = $col_y[$col];
    $txt->translate( $st_x, $st_y );
        
    my $first_line = $first_lines[$col];
    my $last_line = $first_line + $columns[$col];
         
    for ( my $i = $first_line; $i < $last_line; $i++ ) {
    
        if ( $shortened_clue_list[$i] =~ m/^:/ ) {
            $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2);
            $txt->fillcolor('#000000');
        }
        else {
            $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
            $txt->fillcolor('#000000');
        }
        
        my $output = $shortened_clue_list[$i];
        
        if ($three_digit_across) {
            #no digits -- line continuation
            if ($output !~ m/\d+\./) {
                $output = q{        } . $output;
            }
        
            #single digit clue
            if ($output =~ m/^\d\.\s/) {
                $output = q{    } . $output;
            }
            
            #double digit clue
            if ($output =~ m/^\d\d\.\s/) {
                $output = q{  } . $output;
    
            }
            
            if ($output =~ m/[[BLANK]]/) {
                $output = q{  };
            }
            
            if ($output =~ m/ACROSS/) {
                $output = '::ACROSS:::::::';
            }
            
            if ($output =~ m/DOWN/) {
                $output = '::DOWN:::::::';
            }
            
        } else {
            
            #continuation line 
            if ($output !~ m/\d+\./) {
                $output = q{      } . $output;
            }
        
            #single digit clues
            if ($output =~ m/^\d\.\s/) {
                $output = q{  } . $output;
            }
            
                 
            if ($output =~ m/[[BLANK]]/) {
                $output = q{  };
            }
            
            if ($output =~ m/ACROSS/) {
                $output = '::ACROSS:::::::';
            }
            
            if ($output =~ m/DOWN/) {
                $output = '::DOWN:::::::';
            }
            
        }
        $txt->text( $output );
        $st_y = $st_y - $proper_font_size - 2;
        $txt->translate( $st_x, $st_y );
    }#for
}

#************************************************
#************************************************
#************************************************
#************************************************
#************************************************
#************************************************
#************************************************















##########################
#Draw the box here .....


if (0) {
my $grid_size = 405;
my $grid_font = 8;

#make some size adjustments for sunday puzzles
#$day = 'Sunday';
if ($day eq 'Sunday') {
    
    $grid_size = 405;
    $grid_font = 6;
}
}



print $width, " width\n";
$height = $width;

my $sq_size = int( $grid_size / ( $width - 1 ) );
print $sq_size, " sq size\n";

my $box_size = $sq_size * ($width - 1);
print $box_size, " box_size\n\n";
my $box_size_difference = $grid_size - $box_size;
if ($sq_size < 20) {
    $grid_font = 6;
}

#this is the lower, right-hand corner
my $reference_corner_x = 576;
my $reference_corner_y = 36;

#this should put us at the upper, left-hand
#corner of the largest box possible.
my $box_upper_left_x = $reference_corner_x - $box_size;
my $box_upper_left_y = $reference_corner_y + $box_size;


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
$txt->font( $font{'Times'}{'Roman'}, $grid_font);
$txt->fillcolor('#000000');


#fill the gray boxes....
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
my $circle_cnt = 0;
for ( my $i = 0; $i < $height - 1; $i++ ) {
    $y = $st_y - ( ($i + 1) * $sq_size );
    for ( my $j = 0; $j < $width - 1; $j++ ) {

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
            $txt->translate( ( $x + 1 ), ( $y - $grid_font) );
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
for ( my $i = -1; $i < $width; $i++ ) {
    $line->line( $st_x + $box_size, $st_y );
    $line->stroke;

    $st_y -= $sq_size;
    $line->move( $st_x, $st_y );
}

#vertical
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
$line->move( $st_x, $st_y );
for ( my $i = -1; $i < $width; $i++ ) {
    $line->line( $st_x, $st_y - $box_size );
    $line->stroke;

    $st_x += $sq_size;
    $line->move( $st_x, $st_y );
}

my $txt2 = $page->text;
$txt2->font( $font{'Times'}{'Bold'}, 8 );
$txt2->fillcolor('#000000');

$title = $title . "    [$proper_font_size]";
my $l   = int( $txt2->advancewidth($title) );
#$txt2->translate( (578 - $l - $box_size_difference), $reference_corner_y - 10 + $box_size_difference );

$txt2->translate($reference_corner_x - $l, $reference_corner_y - 10);
$txt2->text($title);

#$note = "XXXXXXXXXXXXX";
if ($note ne '') {
    my $note_x = $box_upper_left_x;
    my $note_y = $box_upper_left_y;
   
    $txt->translate( $note_x, ($note_y + 2) );
    $txt->font( $font{'Times'}{'Bold'}, 8 );
    $txt->text( $note );
}

#are there any circles to draw?
if (%circles) {
    my $circle = $page->gfx;
    $circle->strokecolor('#ff0000');
    
    $y = $box_upper_left_y;
    $x = $box_upper_left_x;
    my $circle_cnt = 0;
    for ( my $i = 0; $i < $height; $i++ ) {
        for ( my $j = 0; $j < $width; $j++ ) {    
            $circle_cnt++;
            $x += $sq_size;   
            if ($circles{$circle_cnt}) {
                print "$circle_cnt ... gets a circle ... $x .. $y\n";
                $circle->circle($x + ($sq_size/2), $y - ($sq_size/2), (($sq_size/2) - 1) );
                $circle->stroke;
            }
        }
        $x = $box_upper_left_x;
        $y -= $sq_size;
    }
}

$pdf->save;
$pdf->end();
__END__


    
if (0) {
    #need to work through the individual words here
    #if a word is too long and has hyphens
    #it needs to be split at the last hyphen 
    #and then all the words need to be put back 
    #into the list.
    #
    # hammer-on-the-thumb cries
    # hammer-on-the- thumb cries
    my @tmp_words;
    foreach my $w (@words) {
        
        #if the word has a hyphen
        if ($w =~ m/-/) {
            print $w, "\n";
            #break it up and dump it into the new list
            $w =~ m/(.*)-(.*)/;
            my $str = $1 . '-';
            push (@tmp_words, $str);
            push (@tmp_words, $2);
            print $str, "\n";
            print $2, "\n\n\n";
        } else {
            push (@tmp_words, $w);
        }    
    }
    @words = @tmp_words;
    
}



-------------

if (0) {
#drop shadow
my $shadow = $page->gfx;
my $shadow_height = 3;
my $x = $reference_corner_x - $box_size;
print "$x -----------------------------------\n";
my $y = $reference_corner_y - $shadow_height;
print "$y -----------------------------------\n";
$shadow->rect( $reference_corner_x - $box_size + $shadow_height, $reference_corner_y - $shadow_height, $box_size, $shadow_height );
$shadow->fillcolor('#cccccc');
$shadow->fill;
}
if (0) {
my $shadow2 = $page->gfx;
$x = $reference_corner_x;
$y = $reference_corner_y - $shadow_height;
print $x, ".....................................\n";
#$shadow2->rect( 576, 30, 3, 405 );
$shadow2->rect( $x, $y, $shadow_height, $box_size );
$shadow2->fillcolor('#cccccc');
$shadow2->fill;
}

if (0) {
my $gfx = $page->gfx;
$gfx->strokecolor('#eeeeee');
$gfx->rrect( 135, 26, 405, 405, 3 );
$gfx->stroke;
}
#drop shadow


-------------------



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


-----------------


    if ($output !~ m/\d+\./) {
        $output = q{      } . $output;
    }

    if ($output =~ m/[[BLANK]]/) {
        $output = q{  };
    }
    
    if ($output =~ m/DOWN/) {
        $output = '::DOWN:::::::';
    }
    
    if ($output =~ m/^\d\.\s/) {
        $output = q{  } . $output;
    }
    
------------------



$check = $first_col + $second_col + $third_col + $fourth_col;
print $first_col,  " 1st\n";
print $second_col, " 2nd \n";
print $third_col,  " 3rd\n";
print $fourth_col, " 4th\n";

print "-------------\n";
print $check, "\n";


================

#move to first column
my $st_x = 36;
my $st_y = 756;
$txt->translate( $st_x, $st_y );

for ( my $i = 0; $i < $first_col; $i++ ) {

    if ( $shortened_clue_list[$i] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2);
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }

    

    my $output = $shortened_clue_list[$i];
   
    
    if ($three_digit_across) {
        #no digits -- line continuation
        if ($output !~ m/\d+\./) {
            $output = q{        } . $output;
        }
    
        #single digit clue
        if ($output =~ m/^\d\.\s/) {
            $output = q{    } . $output;
        }
        
        #double digit clue
        if ($output =~ m/^\d\d\.\s/) {
            $output = q{  } . $output;

        }
        
             
        if ($output =~ m/[[BLANK]]/) {
            $output = q{  };
        }
        
        if ($output =~ m/ACROSS/) {
            $output = '::ACROSS:::::::';
        }
    } else {
        
        #continuation line 
        if ($output !~ m/\d+\./) {
            $output = q{      } . $output;
        }
    
        #single digit clues
        if ($output =~ m/^\d\.\s/) {
            $output = q{  } . $output;
        }
        
             
        if ($output =~ m/[[BLANK]]/) {
            $output = q{  };
        }
        
        if ($output =~ m/ACROSS/) {
            $output = '::ACROSS:::::::';
        }
    }
    $txt->text( $output );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}

### second column
$st_x += 135;
$st_y = 756;
$txt->translate( $st_x, $st_y );

for ( my $i = 0; $i < $second_col; $i++ ) {
    my $clue = $i + $first_col;
    
    #if the first clue in the second 
    #column is the blank line above '::DOWN:::::'
    #skip the line ... 
    #this should put the '::DOWN:::::' on the 
    #top line
    #next if $shortened_clue_list[$clue] =~ m/[[BLANK]]/;

    if ( $shortened_clue_list[$clue] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, ($proper_font_size + 2) );
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }

    my $output = $shortened_clue_list[$clue];
    
    
    if ($three_digit_across) {
        #no digits -- line continuation
        if ($output !~ m/\d+\./) {
            $output = q{        } . $output;
        }
    
        #single digit clue
        if ($output =~ m/^\d\.\s/) {
            $output = q{    } . $output;
        }
        
        #double digit clue
        if ($output =~ m/^\d\d\.\s/) {
            $output = q{  } . $output;

        }
        
        if ($output =~ m/[[BLANK]]/) {
            $output = q{  };
        }
        
        if ($output =~ m/DOWN/) {
            $output = '::DOWN:::::::';
        }
    
    } else {
        
        #continuation line 
        if ($output !~ m/\d+\./) {
            $output = q{      } . $output;
        }
    
        #single digit clues
        if ($output =~ m/^\d\.\s/) {
            $output = q{  } . $output;
        }
        
        if ($output =~ m/[[BLANK]]/) {
            $output = q{  };
        }
        
        if ($output =~ m/DOWN/) {
            $output = '::DOWN:::::::';
        }
    
    }
    
    $txt->text( $output );
    #$txt->text( $shortened_clue_list[$clue] );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}

#### third column
$st_x += 135;
$st_y = 756;
$txt->translate( $st_x, $st_y );
for ( my $i = 0; $i < $third_col; $i++ ) {
    my $clue = $i + $first_col + $second_col;

    if ( $shortened_clue_list[$clue] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2);
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }


my $output = $shortened_clue_list[$clue];
    if ($output !~ m/\d+\./) {
        $output = q{      } . $output;
    }

    if ($output =~ m/[[BLANK]]/) {
        $output = q{  };
    }
    
    if ($output =~ m/DOWN/) {
        $output = '::DOWN:::::::';
    }
    
    if ($output =~ m/^\d\.\s/) {
        $output = q{  } . $output;
    }
    
    $txt->text( $output );
    #$shortened_clue_list[$clue] =~ s/^\.\.\.\./      /;
    #$txt->text( $shortened_clue_list[$clue] );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}

##### fourth column
$st_x += 135;
$st_y = 756;
$txt->translate( $st_x, $st_y );
for ( my $i = 0; $i < $fourth_col; $i++ ) {

    my $clue = $i + $first_col + $second_col + $third_col;
    if ( $shortened_clue_list[$clue] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2);
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    
    
    
    my $output = $shortened_clue_list[$clue];
    if ($output !~ m/\d+\./) {
        $output = q{      } . $output;
    }

    if ($output =~ m/[[BLANK]]/) {
        $output = q{  };
    }
    
    if ($output =~ m/DOWN/) {
        $output = '::DOWN:::::::';
    }
    
    if ($output =~ m/^\d\.\s/) {
        $output = q{  } . $output;
    }
    
    $txt->text( $output );
    
    #$shortened_clue_list[$clue] =~ s/^\.\.\.\./      /;
    #$txt->text( $shortened_clue_list[$clue] );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}

