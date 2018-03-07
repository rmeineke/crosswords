#!/usr/bin/perl

# ? pdf transparency ... see the old_miscellany folder
# ? random color 
# done ---- darker shadow
# Sunday .... 5 columns of clues?
# Circles for special puzzles 
# break on long words ..... w/ dashes 
# done --- needs testing ---- if ::Down:: is on the second line 
#   of the second column .... slide it up


use Carp;
use warnings;
use strict;
use POSIX;
use PDF::API2;

sub get_length {
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

sub split_clue {
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

    $pdf->end;
    return ( $str, $tmp );
}

sub get_font_size {
    my $clues_ref = shift;
    my @strings = @$clues_ref;

    if (0) {
        foreach my $c (@strings) {
            print $c, "\n";
        }
    }
    my $total_height;

    #720 + 300 + 300 + 300 = 1620

    my $i;
    for ( $i = 13; $i > 5; $i-- ) {
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
                    push( @new_array, $str );
                    push( @new_array, $whats_left );

                    $changes++;
                }
                else {
                    push( @new_array, $s );
                }
            }
            @strings = @new_array;
        }

        my $num_clues = @strings;
        print $num_clues, " num_clues\n";
        $total_height = $num_clues * ( $i + 2 );
        print $total_height, " height\n";


        #720 + 300 + 300 + 300 = 1620
        if ( $total_height < 1620 ) {
            print "about to return total_height: ", $total_height, "\n";
            print "about to return font size: ",    $i,            "\n";
            return ( $i, @strings );
        }
        else {
            @strings = @$clues_ref;
        }
    }
}

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
        print $str_count, "..... $str\n";
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

my $note;
if ($num_strings - $num_clues) {
    print "FOUND A NOTE ...............\n";
    $note = pop(@strings);
}
if (defined $note) {
    print $note, "\n";
}
#that should be the last of the strings.



# if their is a section of extra info it should be here


# gext 
#
# 4 bytes title .... looking for gext
# 2 byte length
# 2 byte checksum
# 
# length long data string .... 
#
# 0x80 means the square is circled
my @circles;
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
                print "$i -- circle\n";
                push (@circles, $i);
            }
            
        }
    }
}

print @circles;
if (0) {
my $byte_cnt = 0;
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {
    $byte_cnt++;
}
print "---------------------------\n";
print "$byte_cnt .... byte_cnt\n";
print "===========================\n";
}



#we are done w/ the input
close $IN;





####################
####################
####################
####################
#exit(0);
####################
####################
####################
####################
####################



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


if (0) {
print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n";
print join (',', @across);
print "\n\n";
print "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n";
print join (',', @down);
print "\n\n";
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
unshift( @across_list, ":: ACROSS :::::::" );

$length = @down_list;
for ( my $i = 0; $i < $length; $i++ ) {
    if ( $down[$i] < 10 ) {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
    else {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
}
unshift( @down_list, ":: DOWN :::::::" );

#put a gap between the acrosses and the downs
unshift( @down_list, "          " );



my @clue_list = ( @across_list, @down_list );
if (0) {
foreach my $c (@clue_list) {
    print $c, "\n";
}
}



my ( $proper_font_size, @final_clue_list ) = get_font_size( \@clue_list );

#insert an extra space if it is a 
#single-digit clue
if (0) {
    foreach my $c (@final_clue_list) {
        if ($c =~ m/^\d\.\ .*/) {
            $c =~ s/\.\ /\.   /;        
        }
    }
}

print $proper_font_size, " <----- font\n";
my $lines = @final_clue_list;
print $lines, " lines in clue list\n";




my $first_col = ceil( 720 / ( $proper_font_size + 2 ) );


if ($final_clue_list[$first_col - 1] eq ':: DOWN :::::::') {
    
    print ">>>>>>>>>>>>>>> the down\n";
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

my $pdf = PDF::API2->new( -file => "$file_out" );
my $page = $pdf->page;



if (0) {
my $box = $page->gfx;
$box->fillcolor('#dddddd');
$box->rect(36, 36, 125, 720);
$box->fill();

$box->rect(171, 456, 125, 300);
$box->fill();

$box->rect(306, 456, 125, 300);
$box->fill();

$box->rect(441, 456, 125, 300);
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

if ($note ne '') {
    my $st_x = 171;
    my $st_y = 445;
    $txt->translate( $st_x, $st_y );
    $txt->font( $font{'Times'}{'Bold'}, 8 );
    $txt->text( $note );
    
}
$txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
#move to first column
my $st_x = 36;
my $st_y = 756;
$txt->translate( $st_x, $st_y );


$check = $first_col + $second_col + $third_col + $fourth_col;
print $first_col,  " 1st\n";
print $second_col, " 2nd \n";
print $third_col,  " 3rd\n";
print $fourth_col, " 4th\n";

print "-------------\n";
print $check, "\n";

for ( my $i = 0; $i < $first_col; $i++ ) {

    if ( $final_clue_list[$i] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }

    $final_clue_list[$i] =~ s/^\.\.\.\./      /;
    $txt->text( $final_clue_list[$i] );
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
    next if $clue eq '';

    if ( $final_clue_list[$clue] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    $final_clue_list[$clue] =~ s/^\.\.\.\./      /;
    

    $txt->text( $final_clue_list[$clue] );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}

#### third column
$st_x += 135;
$st_y = 756;
$txt->translate( $st_x, $st_y );
for ( my $i = 0; $i < $third_col; $i++ ) {
    my $clue = $i + $first_col + $second_col;

    if ( $final_clue_list[$clue] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }

    $final_clue_list[$clue] =~ s/^\.\.\.\./      /;
    $txt->text( $final_clue_list[$clue] );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}

##### fourth column
$st_x += 135;
$st_y = 756;
$txt->translate( $st_x, $st_y );
for ( my $i = 0; $i < $fourth_col; $i++ ) {

    my $clue = $i + $first_col + $second_col + $third_col;
    if ( $final_clue_list[$clue] =~ m/^:/ ) {
        $txt->font( $font{'Times'}{'Bold'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    else {
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');
    }
    $final_clue_list[$clue] =~ s/^\.\.\.\./      /;
    $txt->text( $final_clue_list[$clue] );
    $st_y = $st_y - $proper_font_size - 2;
    $txt->translate( $st_x, $st_y );
}


if (0) {
#drop shadow
my $shadow = $page->gfx;
$shadow->rect( 177, 30, 405, 6 );
$shadow->fillcolor('#aaaaaa');
$shadow->fill;

my $shadow2 = $page->gfx;
$shadow2->rect( 576, 30, 6, 405 );
$shadow2->fillcolor('#aaaaaa');
$shadow2->fill;
}




##########################
#Draw the box here .....

print $width, " width\n";
$height = $width;
my $sq_size = int( 405 / ( $width - 1 ) );
print $sq_size, " sq size\n";

my $box_size = $sq_size * ($width - 1);
print $box_size, " box_size\n\n";

#this is the lower, right-hand corner
$st_x = 576;
$st_y = 36;

#this should put us at the upper, left-hand
#corner of the largest box possible.
$st_x -= $box_size;
$st_y += $box_size;

if (0) {
my $circle = $page->gfx;
$circle->strokecolor('#ff0000');
$circle->circle(100,100,($sq_size/2));
$circle->stroke;
}

print "--------\n$st_x, $st_y, $box_size\n----------\n";


my $box = $page->gfx;
$box->fillcolor('#aaaaaa');

#my $height = $width;
my $count = 0;

#start the text .........
$txt = $page->text;
my $font_size = 8;
$txt->font( $font{'Times'}{'Roman'}, $font_size );
$txt->fillcolor('#000000');


#fill the gray boxes....
my ($x, $y);
for ( my $i = 0; $i < $height - 1; $i++ ) {
    $y = $st_y - ( ($i + 1) * $sq_size );
    for ( my $j = 0; $j < $width - 1; $j++ ) {
        $x = $st_x + ( $j * $sq_size );
        if ( $matrix[ $i + 1 ][ $j + 1 ] eq '.' ) {
            #x, y, width, height
            $box->rect( $x, $y, $sq_size, $sq_size );
            $box->fill;
        }
    }
}


########################
# numbers for the boxes
$x = $st_x;
$y = $st_y;
for ( my $i = 0; $i < $height - 1; $i++ ) {
    print "$x x $y ..........\n";
    $y = $st_y - ( ($i) * $sq_size );
    for ( my $j = 0; $j < $width - 1; $j++ ) {
        $x = $st_x + ( $j * $sq_size );
        if ( $matrix[ $i + 1 ][ $j + 1 ] eq 'y' ) {
            $count++;
            $txt->translate( ( $x + 1 ), ( $y - 8) );
            $txt->text("$count");
        }
    }
}


#set up the line for grid drawing
my $line = $page->gfx;
$line->linewidth(.5);
$line->strokecolor('#000000');

#upperleft of the grid
$st_x = 36 + 125 + 10;
$st_y = 36 + $box_size;
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
$st_x = 171;
$st_y = 36 + $box_size;
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

$title = $title . "  [$proper_font_size]";
my $l   = int( $txt2->advancewidth($title) );
$txt2->translate( (578 - $l - (405 - $box_size) ), 26 );
$txt2->text($title);


$pdf->save;
$pdf->end();
print @circles;
__END__
113 lines in clue list
52 1st
21 2nd 
21 3rd
19 4th
-------------
113
52 1st
21 2nd 
21 3rd
19 4th
-------------
