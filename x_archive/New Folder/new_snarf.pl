#!/usr/bin/perl

use Carp;
use warnings;
use strict;
use POSIX;
use PDF::API2;

use Benchmark;

#my $DEBUG = 1;
#my $SOLVE = 1;

sub carve_up_long_string {

    #print "carve_up_long_string() called\n";
    #this is the entire clue payload
    #dumped into one long string
    my $str = shift;

    print $str, "\n";

    #passed in the day in case it was
    #sunday ... to save some cycles thru
    #the font processing
    my $day = shift;

    my $max_height = 1620;
    if ( $day eq 'Sunday' ) {
        $max_height = 1920;
    }

    #print "max_height == $max_height\n";

    #replace any dashes with '-|'
    #$str =~ s/-/-|/g;

    #replace any slashes with '/|'
    #$str =~ s/\//\/|/g;

    #now the words are broken out into an array
    #spiltting on the pipe character and the space
    #this should retain any hyphens and slashes
    my @words = split /\s/, $str;
        #my @words = split /[| +]/, $str;

    my $pdf   = PDF::API2->new();
    my $page  = $pdf->page;
    my %font
        = (
        Times => { Roman => $pdf->corefont( 'Times', -encoding => 'latin1' ) }
        );

    my $txt = $page->text;
    my @temp_words = ();
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

        print $num_words, " == num_words\n";

        #while the length is still less than one column wide (125pts)
        #add the next word to the end and test again
        my $str;

        for ( my $i = 0; $i < $num_words; $i++ ) {
            print "/////////////////////////////////////$words[$i]\n";
            $words[$i] =~ s/^\s+//;
            push(@temp_words, ">>$words[$i]<<");
        }
    }
    $pdf->end;
    
    #@temp_words = ();
    #$temp_words[0] = '1. test';
    #$temp_words[1] = '2. test';
    #$temp_words[2] = '3.                  test';
    #$temp_words[3] = '4. test';
    #$temp_words[4] = '5.                test';
    #$temp_words[5] = '6. test';
    #$temp_words[6] = '7.                 test';
    #$temp_words[7] = '8.                               test';
    
    $end_font = 12;
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

my $buffer;
my $bytesread = 0;

#snarf the file in
my $document = do {
    local $/ = undef;
    <$IN>;
};
close $IN;

#print length $document, "\n";
my $document_length = length $document;

my $offset = 44;
my $width = ord substr $document, $offset, 1;
#print $width, " == width \n";

$offset++;
my $height = ord substr $document, $offset, 1;
#print $height, " == height \n";

my $squares = $width * $height;
#print $squares, " == squares\n";

$offset++;
my $num_clues = substr $document, $offset, 1;
$offset++;
$num_clues .= substr $document, $offset, 1;
$num_clues = ord $num_clues;
#print $num_clues, "\n";

print "\n";
$offset = 52;
my $solution = substr $document, $offset, $squares;
#print $solution, "\n";


print "\n";
$offset = $offset + $squares;
my $grid = substr $document, $offset, $squares;
#print "\nHere is the grid w/ no formatting\n";
#print $grid, "\n";


#lay the solution string out in a matrix
my @matrix;

#add an extra row/column ....
#$width++;
#$height++;

#print $width . " x " . $height . "\n";

#Sept 17, 2013 grid was not square
#so this broke...
#
#it is 16 wide by 15 high
#
#lay some dots around the top and left
for ( my $i = 0; $i < $height + 1; $i++ ) {
    $matrix[$i][0] = '.';
}

for ( my $i = 0; $i < $width + 1; $i++ ) {
    $matrix[0][$i] = '.';
}

#read in and drop into the matrix the
#dots and dashes that indicate clues
#and blanks
my $char_cnt = 0;
for ( my $i = 1; $i < $height + 1; $i++ ) {
    for ( my $j = 1; $j < $width + 1; $j++ ) {
        $matrix[$i][$j] = substr $grid, $char_cnt, 1;
        $char_cnt++;
    }
}


$offset = $offset + $squares;
#print $offset, " == offset just before the clue strings\n";
my $str      = q{};
my $char     = q{};
my $line_cnt = 0;
my @strings  = ();
while ( $line_cnt < $num_clues + 4 ) {
    $char = substr $document, $offset, 1;
    if ( $char eq "\0" ) {
        push( @strings, $str );
        print $line_cnt + 1, "-- ", $str, "\n";
        $str = q{};
        $line_cnt++;
        print $line_cnt, " == line_cnt\n";
    } else {
        $str .= $char;
    }
    $offset++;
}

my $title = shift @strings;

print $title, "\n";

my $day = '?';
my $theme = q{?};
if ( $title =~ m/sunday/ixms ) {
    print "This is a sunday puzzle\n";
    $day = 'Sunday';
    $theme = get_sunday_theme($title);
    print "..............................................>$theme<\n";
    $title = get_sunday_title($title);
    print ">$title<...........................................\n";
}


my $author = shift @strings;

print $author, "\n";
my $copyright = shift @strings;

print $copyright, "\n\n";

my $num_strings = @strings;

#print "Num clue strings == $num_strings\n";

#the last string provided is a 'note'
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
else {
    print "There is no note on this puzzle\n";
    if ($day eq 'Sunday') {
        $note = $theme;
    }
}
#that should be the last of the strings.

#tweaking the clue matrix here
#
#this will change any dashes to the letter 'y'
#if they will need to be numbered

#print $width,  " == width\n";
#print $height, " == height\n";
for ( my $i = 0; $i < $height + 1; $i++ ) {
    for ( my $j = 0; $j < $width + 1; $j++ ) {
        next if $matrix[$i][$j] eq '.';
        if ( $i == 1 || $matrix[ ( $i - 1 ) ][$j] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }    #if
    }    #for
}    #for

if (0) {
    for ( my $i = 1; $i < $height + 1; $i++ ) {
        for ( my $j = 1; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j];
        }
        print "\n";
    }
}

#print $width,  " == width\n";
#print $height, " == height\n";
for ( my $j = 0; $j < $width + 1; $j++ ) {
    for ( my $i = 0; $i < $height + 1; $i++ ) {
        next if ( $matrix[$i][$j] eq '.' || $matrix[$i][$j] eq 'y' );
        if ( $j == 1 || $matrix[$i][ ( $j - 1 ) ] eq '.' ) {
            $matrix[$i][$j] = 'y';
        }    #if
    }    #for
}    #for

if (0) {
    for ( my $i = 1; $i < $height + 1; $i++ ) {
        for ( my $j = 1; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j];
        }
        print "\n";
    }
}

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
    for ( my $i = 1; $i < $height + 1; $i++ ) {
        for ( my $j = 1; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j];
        }
        print "\n";
    }
}

if (0) {
    print "\n\n\n";
    for ( my $i = 0; $i < $height + 1; $i++ ) {
        for ( my $j = 0; $j < $width + 1; $j++ ) {
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
for ( my $i = 1; $i < $height + 1; $i++ ) {
    for ( my $j = 1; $j < $width + 1; $j++ ) {
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

$num_across = @across;
$num_down   = @down;
print $num_across, " == num_across\n";
print $num_down,   " == num_down\n";
my $ttl_clues = $num_across + $num_down;
print $ttl_clues, " == ttl_clues\n\n";


my @across_list;
my @down_list;
foreach my $dir (@clue_order) {
    my $clue = shift(@strings);
    print "clue == ", $clue, "\n";
    if ( $dir eq 'a' ) {
        push( @across_list, $clue );
    }
    else {
        push( @down_list, $clue );
    }
}


my $length = @across_list;
#this will prepend the clue number
#to the front of the clue
for ( my $i = 0; $i < $length; $i++ ) {
    #print "$across[$i]\n";
    #print "$across_list[$i]\n";
        $across_list[$i] = "$across[$i]" . q{. } . "$across_list[$i]";
            #print "$across_list[$i]\n";

}
unshift( @across_list, "999. ::ACROSS:::::::" );


$length = @down_list;
#this will prepend the clue number
#to the front of the clue
for ( my $i = 0; $i < $length; $i++ ) {
    $down_list[$i] = "$down[$i]. $down_list[$i]";
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
    my @words = split / /, $c;
    foreach my $w (@words) {
        $long_str = $long_str . q{ } . $w;
    }
}

$long_str =~ s/^\s+//;
#print $long_str, "\n";

my ( $font_size, $ttl_height, @shortened_clue_list )
    = carve_up_long_string( $long_str, $day );



if (0) {
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


#this makes the grid_size dynamic
my $grid_font = 8;
my $grid_size = ceil( 720 - $col_height );
if ( $grid_size > 405 ) {
    $grid_size = 405;
}
if ( $grid_size < 400 ) {
    $grid_font = 6;
}

my $lines = @shortened_clue_list;
#print $lines, " lines in clue list\n";

###################################
# set up the clue columns here

my $line_spacing = 2;

#number of clue lines in the first column
my $first_col = ceil( 720 / ( $proper_font_size + $line_spacing ) );

my @first_col = ();
for ( my $i = 0; $i < $first_col; $i++ ) {
    #push( @first_col, '12.   TEST  ::' );
    push( @first_col, $shortened_clue_list[$i] );
}

$first_col = @first_col;

##############################################
# start to assemble the various parts of the
# pdf output
my $pdf = PDF::API2->new( -file => "$file_out" );
my $page = $pdf->page;
my %font = (
    Times => {
        Bold  => $pdf->corefont( 'Times-Bold', -encoding => 'latin1' ),
        Roman => $pdf->corefont( 'Times',      -encoding => 'latin1' )
    }
);
my $txt = $page->text;
$txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
$txt->fillcolor('#000000');

my $x = 50;
my $y = 700;
foreach my $c (@shortened_clue_list) {
    $y -= 13;
    $txt->translate($x, $y);
    $txt->text($c);
}

$pdf->save;
$pdf->end();
__END__
