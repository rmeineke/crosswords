#!/usr/bin/perl

use warnings;
use strict;
use Carp;
use POSIX;
use PDF::API2;
use English qw( -no_match_vars );

use Readonly;

use Benchmark;

use Getopt::Long;

our $VERSION = 0.00002;

Readonly my $COLUMN_WIDTH      => 125;
Readonly my $MAX_HEIGHT        => 1650;
Readonly my $SUNDAY_MAX_HEIGHT => 1950;

my $DEBUG = 0;
my $SOLVE = 0;
my $HINT  = 0;
GetOptions(
    's' => \$SOLVE,
    'd' => \$DEBUG,
    'h' => \$HINT
) or croak "Incorrect usage!\n";

#isolate and return the Sunday copyright
sub get_sunday_title {
    my $title = shift;
    my $tmp = q{};
    if ($title =~ m/(^.*\d\d\d\d).*/ixms) {
        $tmp = $1;
    }
    return $tmp;
}

#strip out the theme from the Sunday title
sub get_sunday_theme {
    my $title = shift;
    my $theme = q{};

    #anything after the date should be
    #the puzzle theme
    if ($title =~ m/.*\d\d\d\d(.*)/ixms) {
        $theme = $1;
    }
    #strip off any spaces
    $theme =~ s/^\s//ixms;
    $theme =~ s/\s$//ixms;

    return $theme;
}

sub carve_up_long_string {

    #print "carve_up_long_string() called\n";
    #this is the entire clue payload
    #dumped into one long string
    my $str = shift;

    #print $str, "\n" or croak;

    #passed in the day in case it was
    #sunday ... to save some cycles thru
    #the font processing
    my $day = shift;

    my $max_height = $MAX_HEIGHT;
    if ( $day eq 'Sunday' ) {
        $max_height = $SUNDAY_MAX_HEIGHT;
    }

    #print "max_height == $max_height\n" or croak;

    #replace any dashes w/ '-|'
    $str =~ s/-/-|/gixms;

    #replace any slashes w/ '/|'
    $str =~ s/\//\/|/gixms;

    #the last one screws up dates
    #10/|20/|1968
    #
    #this will cobble any dates back together
    #it might need some tweaking later
    #
    # s:(\d+)\/\|(\d+)\/\|(\d\d\d\d):$1/$2/$3:g
    $str =~ s{(\d\d)\/\|(\d\d)\/\|(\d\d\d\d)}{$1/$2/$3}gixms;

    #print $str or croak;

    #now the words are broken out into an array
    #spiltting on the pipe character and the space
    #this should retain any hyphens and slashes
    my @words = split /[|\s+]/ixms, $str;

    #print @words or croak;
    my $pdf  = PDF::API2->new();
    my $page = $pdf->page;
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

    #print "str_font = $str_font\n" or croak;

    my $end_font;
    my $height       = 0;
    my $minimum_font = 6;

    #process the strings through each font size
    for ( my $i = $str_font; $i > $minimum_font; $i-- ) {

        #print "Checking font size: $i\n" or croak;
        #set the font
        $txt->font( $font{'Times'}{'Roman'}, $i );

        #reset the temp array
        @temp_words = ();

        my $temp_str = q{};

        my $num_words = @words;

        #print $num_words, " == num_words\n" or croak;

        #while the length is still less than one column wide (125pts)
        #add the next word to the end and test again
        my $str;

        for ( my $i = 0; $i < $num_words; $i++ ) {

            #if the next 'word' is just the clue number
            #the last string needs to be pushed onto
            #the stack
            if ( $words[$i] =~ m/\d+\./ixms and $i != 0 ) {
                push @temp_words, $temp_str;
                $temp_str = q{};
            }

            $str      = $temp_str;
            $temp_str = $temp_str . q { } . $words[$i];

            #remove leading space
            $temp_str =~ s/^\s//ixms;

            #remove spaces after any dashes
            $temp_str =~ s/-\s/-/ixms;

            #remove spaces after slashes
            $temp_str =~ s/\/\s/\//ixms;

            #insert a space
            $temp_str =~ s/-and/- and/ixms;
            $temp_str =~ s/-to/- to/ixms;

            #print $temp_str, "<<<<<<<.................\n" or croak;
            if ( $temp_str =~ m/DOWN/xms ) {
                push @temp_words, q{[[BLANK]]};
            }
            $temp_str =~ s/999\.\s//ixms;

            if ($DEBUG) {
                print int( $txt->advancewidth($temp_str) ), q{ -- >>},
                    $temp_str, qq{<<\n}
                    or croak;
            }
            my $new_temp_str;
            if ( $temp_str =~ m/\d+\.\s/ixms ) {
                $new_temp_str = $temp_str;
            }
            else {
                #pad the string to account for the indent
                $new_temp_str = q{      } . $temp_str;
            }
            if ( int( $txt->advancewidth($new_temp_str) ) > $COLUMN_WIDTH ) {
                $i--;
                push @temp_words, $str;
                $temp_str = q{};
            }
        }
        push @temp_words, $temp_str;

        #that should be the end of the clues
        #all pushed on the stack

        my $num_strings = @temp_words;

        #print $num_strings, " ........ num_strings\n" or croak;
        $height = ( $num_strings * ( $i + 2 ) );

        #$print $height, " <<<<<<<<<<<<<<<<<<<<<<< \n" or croak;
        if ( $height < $max_height ) {
            $end_font = $i;
            last;
        }
    }
    $pdf->end;
    return ( $end_font, $height, @temp_words );
}

sub check_for_check_string {
    my $doc    = shift;
    my $offset = shift;
    my $length = shift;

    my $str = substr $doc, $offset, $length;
    chomp $str;
    if ( $str eq 'ACROSS&DOWN' ) {
        return 1;
    }
    return 0;
}

###########################
###########################
######################## file
my $start_time = Benchmark->new;
if ( $#ARGV != 0 ) {
    print "Usage:\tx.pl filename\n" or croak;
    print "\tx.pl Aug2613.puz\n\n"  or croak;
    exit 0;
}

my $file = $ARGV[0];

if ( !-e $file ) {
    print "file ($file) not found\n" or croak;
    exit 0;
}

my $file_in  = $file;
my $file_out = q{};
if ( $file_in =~ m/(.*)\.puz/ixms ) {
    $file_out = $1 . '.pdf';
}
unlink $file_out;

open my $IN, '<', $file_in or croak;
binmode $IN;
my $document = do {
    local $INPUT_RECORD_SEPARATOR = undef;
    <$IN>;
};
close $IN or croak;

print length $document, " == document length\n" or croak;
my $document_length = length $document;
my $offset;

#move past the file checksum
$offset = 2;
my $check_str = check_for_check_string( $document, $offset, 11 );
if ( !$check_str ) {
    print "\nThere seems to be an issue with\n" or croak;
    print "this file .... \n\n\n"               or croak;
    exit 0;
}

$offset = 44;
my $width = ord substr $document, $offset, 1;

#print $width, " == width \n" or croak;

$offset++;
my $height = ord substr $document, $offset, 1;

#print $height, " == height \n" or croak;

my $squares = $width * $height;

#print $squares, " == squares\n" or croak;

$offset++;
my $num_clues = substr $document, $offset, 1;
$offset++;
$num_clues .= substr $document, $offset, 1;
$num_clues = ord $num_clues;

#print $num_clues, "\n" or croak;

$offset = 52;
my $solution;
if ($SOLVE) {
    $solution = substr $document, $offset, $squares;

    #print $solution, "\n" or croak;
    if ($DEBUG) {
        my $j = 0;
        for ( my $i = 0; $i < length $solution; $i++ ) {
            print substr $solution, $j, 1 or croak;
            $j++;
            if ( $j % $width == 0 ) {
                print "\n" or croak;
            }
        }
    }
}
$offset = $offset + $squares;
my $grid = substr $document, $offset, $squares;

if ($DEBUG) {
    print "\nHere is the grid w/ no formatting\n" or croak;
    print $grid, "\n" or croak;
}

if ($DEBUG) {
    print "\nHere is the grid formatted\n" or croak;
    my $j = 0;
    for ( my $i = 0; $i < length $grid; $i++ ) {
        print substr $grid, $j, 1 or croak;
        $j++;
        if ( $j % $width == 0 ) {
            print "\n" or croak;
        }
    }
}

#lay the solution string out in a matrix
my @matrix;

#print $width . " x " . $height . "\n" or croak;

#Sept 17, 2013 grid was not square
#so this broke...
#
#it is 16 wide by 15 high
#
#lay some dots around the top and left
for ( my $i = 0; $i < $height + 1; $i++ ) {
    $matrix[$i][0] = q{.};
}

for ( my $i = 0; $i < $width + 1; $i++ ) {
    $matrix[0][$i] = q{.};
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

if ($DEBUG) {
    print "Here is is the grid matrix..........\n"          or croak;
    print " -- with the exterior buffer on top and left.\n" or croak;
    for ( my $i = 0; $i < $height + 1; $i++ ) {
        for ( my $j = 0; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j] or croak;
        }
        print "\n" or croak;
    }
}

my $str      = q{};
my $char     = q{};
my $line_cnt = 0;
my @strings  = ();

$offset = $offset + $squares;
Readonly my $HDR_STRINGS => 4;

#print $offset, " == offset just before the clue strings\n" or croak;
while ( $line_cnt < $num_clues + $HDR_STRINGS ) {
    $char = substr $document, $offset, 1;
    if ( $char eq "\0" ) {
        push @strings, $str;

        #print $line_cnt + 1, "-- ", $str, "\n" or croak;
        $str = q{};
        $line_cnt++;

        #print $line_cnt, " == line_cnt\n" or croak;
    }
    else {
        $str .= $char;
    }
    $offset++;
}

my $title = shift @strings;
print $title, "\n" or croak;

my $day   = q{?};
my $theme = q{?};
if ( $title =~ m/sunday/ixms ) {
    print "This is a sunday puzzle\n" or croak;
    $day   = 'Sunday';
    $theme = get_sunday_theme($title);
    print "..............................................>$theme<\n" or croak;
    $title = get_sunday_title($title);
    print ">$title<...........................................\n" or croak;
}

my $author = shift @strings;

print $author, "\n" or croak;
my $copyright = shift @strings;

print $copyright, "\n\n" or croak;

my $num_strings = @strings;

#print "Num clue strings == $num_strings\n" or croak;

#the last string provided, if there is one, will be a 'note'
my $note = q{};
if ( $num_strings - $num_clues ) {
    $note = pop @strings;

    #chop off the terminating null char
    chop $note;
}

#check to see if there is anything left to read
if ( length $note ) {
    print length $note, "\n" or croak;
    print ">>>>>>>>>>>>>>>>$note<<<<<<<<<<<<<<\n" or croak;
}
else {
    print "There is no note on this puzzle\n" or croak;
    if ( $day eq 'Sunday' ) {
        $note = $theme;
    }
}

#that should be the last of the strings.

if ($DEBUG) {
    print "===================\n" or croak;
    foreach my $c (@strings) {
        print $c, "\n" or croak;
    }
}

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
my $index;
Readonly my $SKIP => 4;
if ( index($document, q{GEXT}) != -1 ) {
    $index = index $document, q{GEXT};
    print "GEXT FOUND ..... $index\n";
    #hop past the 'GEXT' in the document
    $index = $index + $SKIP;

    #grab next 2 bytes and make them a
    #string ... then see what the ordinal
    #is ... should be the length of the 
    #circle data info
    my $c2 = substr $document, $index, 1;
    $index++;
    my $c1 = substr $document, $index, 1;
    my $l_str = sprintf ("%02x%02x", ord $c1, ord $c2);
    my $l = hex $l_str;
    print "CIRCLE LENGTH == $l\n";
    #blow past checksum
    $index += 2;

    #cycle thru the next $l bytes and check the 
    #eighth bit .... if it is set then there 
    #is a circle there
    for ( my $i = 0; $i < $l; $i++ ) {
        $index++;
        $char = substr $document, $index, 1;
        if ( substr( unpack( 'B8', $char ), 0, 1 ) eq '1' ) {
            $circles{$i} = 1;
            #print "CIRCLE ---> $i\n";
        }
    }
}

my $l;
my %rebus;
if ($HINT) {
    if ( index($document, q{GRBS}) != -1 ) {
        $index = index $document, q{GRBS};
        print "GRBS FOUND ..... $index\n";
        #hop past the 'GRBS' in the document
        $index = $index + $SKIP;
    
        #grab next 2 bytes and make them a
        #string ... then see what the ordinal
        #is ... should be the length of the 
        #circle data info
        my $c2 = substr $document, $index, 1;
        $index++;
        my $c1 = substr $document, $index, 1;
        my $l_str = sprintf ("%02x%02x", ord $c1, ord $c2);
        my $l = hex $l_str;
        print "REBUS LENGTH == $l\n";
       
        #blow past checksum
        $index += 2;
    
        for ( my $i = 0; $i < $l; $i++ ) {
            $char_cnt++;
            $char = substr $document, $char_cnt, 1;
            if ( ord $char > 0 ) {
                $rebus{$i} = 1;
            }
        }
    }
}

#REBUS Table
if ($HINT) {
    if ( index($document, q{GRBS}) != -1 ) {
        $index = index $document, q{GRBS};
        print "GRBS FOUND ..... $index\n";
        #hop past the 'GRBS' in the document
        $index = $index + $SKIP;
    
        #grab next 2 bytes and make them a
        #string ... then see what the ordinal
        #is ... should be the length of the 
        #circle data info
        my $c2 = substr $document, $index, 1;
        $index++;
        my $c1 = substr $document, $index, 1;
        my $l_str = sprintf ("%02x%02x", ord $c1, ord $c2);
        my $l = hex $l_str;
        print "REBUS LENGTH == $l\n";
       
        #blow past checksum
        $index += 2;
    
        for ( my $i = 0; $i < $l; $i++ ) {
            $char_cnt++;
            $char = substr $document, $char_cnt, 1;
            if ( ord $char > 0 ) {
                $rebus{$i} = 1;
            }
        }
    }
}

my $l;
#only execute this if the $HINT flag was set
#my %rebus;
if (0) {
    $str = 'rsm1';
    print
        "==========================\nABOUT to look for some REBUS info.....\n"
        or croak;
    $char_cnt = 0;
    while ( $char_cnt < $document_length ) {
        $char_cnt++;
        $char = substr $document, $char_cnt, 1;
        substr( $str, 0, 1 ) = substr( $str, 1, 1 );
        substr( $str, 1, 1 ) = substr( $str, 2, 1 );
        substr( $str, 2, 1 ) = substr( $str, 3, 1 );
        substr( $str, 3, 1 ) = $char;
        last if $str eq 'GRBS';
    }
    $l = 0;
    if ( $str eq 'GRBS' ) {
        print "REBUS found\n==========================\n" or croak;
        $char_cnt++;
        $l = substr $document, $char_cnt, 1;
        $char_cnt++;
        $l .= substr $document, $char_cnt, 1;
        $l = ord $l;

        #print "$l ................\n" or croak;

        #blow past checksum
        $char_cnt += 2;
        for ( my $i = 0; $i < $l; $i++ ) {
            $char_cnt++;
            $char = substr $document, $char_cnt, 1;
            if ( ord $char > 0 ) {
                $rebus{$i} = 1;

                #print "rebus -- $i\n" or croak;
            }
        }
    }

    #Rebus table .... RTBL
    $str = 'rsm1';
    print
        "==========================\nABOUT to look for some REBUS TABLE info.....\n"
        or croak;
    $char_cnt = 0;
    while ( $char_cnt < $document_length ) {
        $char_cnt++;
        $char = substr $document, $char_cnt, 1;
        substr( $str, 0, 1 ) = substr( $str, 1, 1 );
        substr( $str, 1, 1 ) = substr( $str, 2, 1 );
        substr( $str, 2, 1 ) = substr( $str, 3, 1 );
        substr( $str, 3, 1 ) = $char;
        last if $str eq 'RTBL';
    }
    $l = 0;
    if ( $str eq 'RTBL' ) {
        print "REBUS TABLE found\n==========================\n" or croak;
        $char_cnt++;
        $l = substr $document, $char_cnt, 1;
        $char_cnt++;
        $l .= substr $document, $char_cnt, 1;
        $l = ord $l;

        #print "$l ................\n" or croak;

        #blow past checksum
        $char_cnt += 2;
        for my $i (1..$l) {
            $char_cnt++;
            $char = substr $document, $char_cnt, 1;

            #print $char or croak;
        }
        print "\n" or croak;
    }
    print " ---------------------- REBUS done\n" or croak;
}

#tweaking the clue matrix here
#
#this will change any dashes to the letter 'y'
#if they will need to be numbered

for ( my $i = 0; $i < $height + 1; $i++ ) {
    for ( my $j = 0; $j < $width + 1; $j++ ) {
        next if $matrix[$i][$j] eq q{.};
        if ( $i == 1 || $matrix[ ( $i - 1 ) ][$j] eq q{.} ) {
            $matrix[$i][$j] = q{y};
        }    #if
    }    #for
}    #for

if ($DEBUG) {
    for ( my $i = 1; $i < $height + 1; $i++ ) {
        for ( my $j = 1; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j] or croak;
        }
        print "\n" or croak;
    }
}

for ( my $j = 0; $j < $width + 1; $j++ ) {
    for ( my $i = 0; $i < $height + 1; $i++ ) {
        next if ( $matrix[$i][$j] eq q{.} || $matrix[$i][$j] eq q{y} );
        if ( $j == 1 || $matrix[$i][ ( $j - 1 ) ] eq q{.} ) {
            $matrix[$i][$j] = q{y};
        }    #if
    }    #for
}    #for

if ($DEBUG) {
    for ( my $i = 1; $i < $height + 1; $i++ ) {
        for ( my $j = 1; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j] or croak;
        }
        print "\n" or croak;
    }
}

#here is a weird edge case
#august 29 2013
#had a blank square in the middle of it
for ( my $i = 0; $i < $height; $i++ ) {
    for ( my $j = 0; $j < ( $width - 1 ); $j++ ) {
        next if $matrix[$i][$j] eq q{.};

        #Sprint $i . ' - ' . $j, "\n" or croak;
        if (   $matrix[ ( $i - 1 ) ][$j] eq q{.}
            && $matrix[$i][ ( $j + 1 ) ] eq q{.}
            && $matrix[ ( $i + 1 ) ][$j] eq q{.}
            && $matrix[$i][ ( $j - 1 ) ] eq q{.} )
        {
            $matrix[$i][$j] = 'X';
        }    #if
    }    #for
}    #for

if ($DEBUG) {
    for ( my $i = 1; $i < $height + 1; $i++ ) {
        for ( my $j = 1; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j] or croak;
        }
        print "\n" or croak;
    }
}

if ($DEBUG) {
    print "\n\n\n" or croak;
    for ( my $i = 0; $i < $height + 1; $i++ ) {
        for ( my $j = 0; $j < $width + 1; $j++ ) {
            print $matrix[$i][$j] or croak;
        }
        print "\n" or croak;
    }
    print "\n\n\n" or croak;
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
for ( my $i = 1; $i < $height + 1; $i++ ) {
    for ( my $j = 1; $j < $width + 1; $j++ ) {
        next if $matrix[$i][$j] eq q{.};

        my $a = 0;
        my $d = 0;

        #any position and preceded by a dot (.)
        if ( $matrix[$i][$j] eq q{y} && $matrix[$i][ ( $j - 1 ) ] eq q{.} ) {
            $num_across++;
            $a++;
            push @clue_order, 'a';
        }    #if

        if ( $matrix[$i][$j] eq q{y} && $matrix[ ( $i - 1 ) ][$j] eq q{.} ) {
            $num_down++;
            $d++;
            push @clue_order, 'd';
        }    #if

        #set up the individual across and down lists
        if ( $a || $d ) {
            $clue_count++;
            if ($a) {
                push @across, $clue_count;
            }
            if ($d) {
                push @down, $clue_count;
            }
        }    #if
    }    #for
}    #for

if ($DEBUG) {
    print "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n" or croak;
    print join q{,}, @across or croak;
    print qq{\n\n}                                     or croak;
    print "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n" or croak;
    print join q{,}, @down or croak;
    print qq{\n\n} or croak;
}

$num_across = @across;
$num_down   = @down;
my $ttl_clues = $num_across + $num_down;

#print $ttl_clues, " == ttl_clues\n\n" or croak;

my $three_digit_across = 0;
my $three_digit_down   = 0;

if ( $across[ $num_across - 1 ] > 99 ) {

    #print "There are triple digit ACROSS clues in this puzzle\n" or croak;
    $three_digit_across++;
}

if ( $down[ $num_down - 1 ] > 99 ) {

    #print "There are triple digit DOWN clues in this puzzle\n" or croak;
    $three_digit_down++;
}

my @across_list;
my @down_list;
foreach my $dir (@clue_order) {
    my $clue = shift @strings;
    if ( $dir eq 'a' ) {
        push @across_list, $clue;
    }
    else {
        push @down_list, $clue;
    }
}

my $length = @across_list;

#this will prepend the clue number
#to the front of the clue
for ( my $i = 0; $i < $length; $i++ ) {
    if ( $across[$i] < 10 ) {
        $across_list[$i] = "$across[$i]." . q{ } . "$across_list[$i]";
    }
    else {
        $across_list[$i] = "$across[$i]." . q{ } . "$across_list[$i]";
    }

}
unshift @across_list, q{999. ::ACROSS:::::::};

$length = @down_list;

#this will prepend the clue number
#to the front of the clue
for ( my $i = 0; $i < $length; $i++ ) {
    if ( $down[$i] < 10 ) {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
    else {
        $down_list[$i] = "$down[$i]. $down_list[$i]";
    }
}
unshift @down_list, q{999. ::DOWN:::::::};

#put a gap between the acrosses and the downs
unshift @down_list, q{          };

my @clue_list = ( @across_list, @down_list );
if (0) {
    foreach my $c (@clue_list) {
        print $c, "\n" or croak;
    }
}

my $long_str = q{};
foreach my $c (@clue_list) {
    my @words = split m/\s+/ixms, $c;
    foreach my $w (@words) {
        chomp $w;
        $long_str = $long_str . q{ } . $w;
    }
}

$long_str =~ s/^\s+//ixms;

#print $long_str, "\n" or croak;

my ( $font_size, $ttl_height, @shortened_clue_list )
    = carve_up_long_string( $long_str, $day );

if (0) {
    for my $w (@shortened_clue_list) {
        print q{>>>>>}, $w, qq{<<<<<\n} or croak;
    }
}

#print $ttl_height, " == ttl_height\n" or croak;
my $col_height = ceil( ( $ttl_height - 720 ) / 3 );

#print $col_height, " == 2nd/3rd/4th\n" or croak;

#print '$day == ' . $day . "\n" or croak;
#print "\n$font_size\n\n" or croak;
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

if ($DEBUG) {
    print $grid_size, " == grid_size\n" or croak;
    print $grid_font, " == grid_font\n" or croak;
}

#print $proper_font_size, " <----- font\n" or croak;
my $lines = @shortened_clue_list;

#print $lines, " lines in clue list\n" or croak;

###################################
# set up the clue columns here

my $line_spacing = 2;

#number of clue lines in the first column
my $first_col = ceil( 720 / ( $proper_font_size + $line_spacing ) );

my @first_col = ();
for ( my $i = 0; $i < $first_col; $i++ ) {
    push @first_col, $shortened_clue_list[$i];
}

my @temp_col = ();
for ( my $i = $first_col; $i < $lines; $i++ ) {
    push @temp_col, $shortened_clue_list[$i];
}

if (1) {

    #first column widow ??
    #equals a second column orphan
    my $last_str;
    while ( $temp_col[0] !~ m/\s*\d+\.\s/ixms ) {
        $last_str = pop @first_col;

#print $last_str, "-------------------------------------------------\n" or croak;
        unshift @temp_col, $last_str;
    }

    #print "first col should be de-widowed.....\n" or croak;
}

# if the last clue in the first list is
# the down header .... truncate the colum
# by one line .... that should put the header
# on top of the second column
$first_col = @first_col;
if ( $first_col[ $first_col - 1 ] eq '::DOWN:::::::' ) {
    pop @first_col;
    unshift @temp_col, '::DOWN:::::::';
}

if ($DEBUG) {
    print "uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu\n" or croak;
    foreach my $c (@temp_col) {
        print $c, "\n" or croak;
    }
    print "uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu\n" or croak;
}

$first_col = @first_col;

#print $first_col, " first_col\n" or croak;
my $rem = $lines - $first_col;

#print $rem, " rem lines\n" or croak;

my $lines_in_temp_col = @temp_col;

#print "lines_in_temp_col ..... $lines_in_temp_col\n" or croak;
#print "###############################\n" or croak;

my $second_col = ceil( $lines_in_temp_col / 3 );
my $third_col  = $second_col;
my $fourth_col = $rem - $second_col - $third_col;

#print $second_col, " lines in second\n" or croak;
#print $third_col,  " 3rd\n" or croak;
#print $fourth_col, " 4th\n" or croak;

#start
#zero or more spaces
#one or more digits
#the '.' character
#the '_' (space) character
#Sprint "$temp_col[$second_col] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<< \n" or croak;
if (1) {
    if ( $temp_col[$second_col] !~ m/^\s*\d+\.\s/ixms ) {
        $second_col++;
        $third_col--;
    }

    #print $second_col, " lines in second\n" or croak;
    #print $third_col,  " 3rd\n" or croak;
    #print $fourth_col, " 4th\n" or croak;

    if ( $temp_col[ ( $second_col + $third_col ) ] !~ m/^\s*\d+\.\s/ixms ) {
        $third_col++;
        $fourth_col--;
    }
}

#print $second_col, " lines in second\n" or croak;
#print $third_col,  " 3rd\n" or croak;
#print $fourth_col, " 4th\n" or croak;

my @second_col;
my @third_col;
my @fourth_col;

for ( my $i = 0; $i < $second_col; $i++ ) {
    push @second_col, $temp_col[$i];
}

for ( my $i = $second_col; $i < ( $second_col + $third_col ); $i++ ) {
    push @third_col, $temp_col[$i];
}

for (
    my $i = ( $second_col + $third_col );
    $i < ( $second_col + $third_col + $fourth_col );
    $i++
    )
{
    push @fourth_col, $temp_col[$i];
}

#exit(0);

#print $check, "\n" or croak;

##############################################
# start to assemble the various parts of the
# pdf output
my $pdf = PDF::API2->new( -file => "$file_out" );
my $page = $pdf->page;

#print grey columns behind the clues for
#debugging purposes
if ($DEBUG) {
    my $box = $page->gfx;
    $box->fillcolor('#eeeeee');
    $box->rect( 36, 36, 133, 730 );
    $box->fill();

    $box->rect( 171, 446, 133, 320 );
    $box->fill();

    $box->rect( 306, 446, 133, 320 );
    $box->fill();

    $box->rect( 441, 446, 133, 320 );
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

$first_col  = @first_col;
$second_col = @second_col;
$third_col  = @third_col;
$fourth_col = @fourth_col;
my @columns = ( $first_col, $second_col, $third_col, $fourth_col );
my @first_lines = (
    0, $first_col,
    $first_col + $second_col,
    $first_col + $second_col + $third_col,
);

my @col_x = ( 36, 171, 306, 441 );

####
#changed these from 756 to 766 to maximize the use of the
#top margin .... might need to be dropped back down
my @col_y = ( 756, 756, 756, 756 );
for ( my $col = 0; $col < 4; $col++ ) {

   #print "$col -- $columns[$col] -- $col_x[$col] -- $col_y[$col]\n" or croak;

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

#print " >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>$output<<<<<<<<<<<\n" or croak;

        if ( $top_line == 1 and $output =~ m/BLANK/xms ) {
            $last_line++;
            $first_lines[2]++;
            $first_lines[3]++;
            $columns[2]--;
            $columns[3]--;
            next;
        }

        if ($three_digit_across) {

            #no digits -- line continuation
            if ( $output !~ m/\d+\./ixms ) {
                $output = q{        } . $output;
            }

            #single digit clue
            if ( $output =~ m/^\d\.\s/ixms ) {
                $output = q{    } . $output;
            }

            #double digit clue
            if ( $output =~ m/^\d\d\.\s/ixms ) {
                $output = q{  } . $output;

            }

            if ( $output =~ m{[[BLANK]]}xms ) {
                $output = q{  };
            }

            if ( $output =~ m/ACROSS/xms ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::ACROSS:::::::';
            }

            if ( $output =~ m/DOWN/xms ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::DOWN:::::::';
            }

        }
        else {
            #continuation line
            if ( $output !~ m/\d+\./ixms ) {
                $output = q{      } . $output;
            }

            #single digit clues
            if ( $output =~ m/^\d\.\s/ixms ) {
                $output = q{  } . $output;
            }

            if ( $output =~ m/[[BLANK]]/xms ) {
                $output = q{  };
            }

            if ( $output =~ m/ACROSS/xms ) {
                $txt->font( $font{'Times'}{'Bold'}, $proper_font_size + 2 );
                $output = '::ACROSS:::::::';
            }

            if ( $output =~ m/DOWN/xms ) {
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
#print $width, " width\n" or croak;
#
#this next line screwed things up
#when the grid was not a perfect square!
#$height = $width;

print "setting up the grid for printing\n" or croak;

print "$width .... width\n" or croak;
print "$height .... height\n" or croak;
my $sq_size = int( $grid_size / ($width) );

#print $sq_size, " sq size\n" or croak;

my $box_size_width  = $sq_size * ($width);
my $box_size_height = $sq_size * ($height);

#print $box_size_width,  " == box_size_width\n" or croak;
#print $box_size_height, " == box_size_height\n" or croak;

#print $box_size, " box_size\n\n" or croak;
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

#print $box_upper_left_x, " == box_upper_left_x\n" or croak;
#print $box_upper_left_y, " == box_upper_left_y\n" or croak;

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
print "\n" or croak;
for ( my $i = 0; $i < $height; $i++ ) {
    $y = $st_y - ( ( $i + 1 ) * $sq_size );
    for ( my $j = 0; $j < $width; $j++ ) {

        #print "$i .. $j\n" or croak;

        $x = $st_x + ( $j * $sq_size );
        if ( $matrix[ $i + 1 ][ $j + 1 ] eq q{.} ) {
            $box->rect( $x, $y, $sq_size, $sq_size );
            $box->fill;
        }
    }
}

########################
# numbers for the boxes

$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
for ( my $i = 0; $i < $height; $i++ ) {

    #print "$x x $y ..........\n" or croak;
    $y = $st_y - ( ($i) * $sq_size );
    for ( my $j = 0; $j < $width; $j++ ) {
        $x = $st_x + ( $j * $sq_size );
        if ( $matrix[ $i + 1 ][ $j + 1 ] eq q{y} ) {
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

#$width--;

#horizontal
for ( my $i = -1; $i < $height; $i++ ) {
    $line->line( $st_x + $box_size_width, $st_y );
    $line->stroke;

    $st_y -= $sq_size;
    $line->move( $st_x, $st_y );
}

#vertical
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
$line->move( $st_x, $st_y );

for my $i (-1..($width-1)) {
    $line->line( $st_x, $st_y - $box_size_height );
    $line->stroke;

    $st_x += $sq_size;
    $line->move( $st_x, $st_y );
}

my $txt2 = $page->text;
$txt2->font( $font{'Times'}{'Bold'}, 8 );
$txt2->fillcolor('#000000');

$title = $title . "    [$proper_font_size]";
$l     = int( $txt2->advancewidth($title) );

#$txt2->translate( (578 - $l - $box_size_difference), $reference_corner_y - 10 + $box_size_difference );

$txt2->translate( $reference_corner_x - $l, $reference_corner_y - 10 );
$txt2->text($title);

#$note = "XXXXXXXXXXXXX";
if ( $note ne q{} ) {
    my $note_x = $box_upper_left_x;
    my $note_y = $box_upper_left_y;

    $txt->translate( $note_x, ( $note_y + 2 ) );
    $txt->font( $font{'Times'}{'Bold'}, 8 );
    $txt->text($note);
}

#$height--;
#$width++;
#are there any circles to draw?
if (%circles) {
    my $circle = $page->gfx;
    $circle->strokecolor('#ff0000');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    #print "$x .. $y <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< CIRCLES\n" or croak;
    my $circle_cnt = -1;

    #print "$width x $height >>>>>>>>>>>>>>>>>>>>> CIRCLES\n" or croak;
    for my $i (0..($height-1)) {
        for my $j (0..($width-1)) {
            $circle_cnt++;

            #print "$i x $j\n" or croak;
            if ( $circles{$circle_cnt} ) {

#print "$circle_cnt ... gets a circle ... $x .. $y   ----- $i x $j\n" or croak;
                $circle->circle(
                    $x + ( $sq_size / 2 ),
                    $y - ( $sq_size / 2 ),
                    ( ( $sq_size / 2 ) - 1 )
                );
                $circle->stroke;
            }
            $x += $sq_size;
        }

        #print "$i ... reset \$x ... $x\n" or croak;
        $x = $box_upper_left_x;

        #print "$i ... reset \$x ... $x\n" or croak;

        $y -= $sq_size;
    }
}

#are there any REBUS to draw?
if ( %rebus && $HINT ) {
    print "About to draw the REBUS hints\n";
    my $txt      = $page->text;
    my $eg_trans = $pdf->egstate();
    $eg_trans->transparency(0.9);
    $txt->font( $font{'Times'}{'Roman'}, $sq_size );
    $txt->egstate($eg_trans);
    $txt->fillcolor('#0000ff');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    #print "$x .. $y <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n" or croak;
    my $rebus_cnt = -1;

    #print "$width x $height >>>>>>>>>>>>>>>>>>>>>\n" or croak;
    for my $i (1..$height) {
        for my $j (1..$width) {
            $rebus_cnt++;

            #print "$i x $j\n" or croak;
            if ( $rebus{$rebus_cnt} ) {
                $txt->translate( $x + ( .25 * $sq_size ), $y - ($sq_size) );
                $txt->text(q{*});
            }
            $x += $sq_size;
        }

        #print "$i ... reset \$x ... $x\n" or croak;
        $x = $box_upper_left_x;

        #print "$i ... reset \$x ... $x\n" or croak;

        $y -= $sq_size;
    }
}

# SOLUTION
if ($SOLVE) {
    my $txt       = $page->text;
    my $font_size = ceil($sq_size) - 4;

    print $font_size, " == font_size .... solution\n" or croak;

    my $eg_trans = $pdf->egstate();
    $eg_trans->transparency(0.2);
    $txt->egstate($eg_trans);

    $txt->font( $font{'Times'}{'Roman'}, $font_size );
    $txt->fillcolor('#1E90FF');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    my $char_cnt = -1;

    for my $i (1..$height) {
        for my $j (1..$width) {
            $char_cnt++;

       #$txt->translate( $x + ( .25 * $sq_size ) - 2 , $y - ( $sq_size ) + 2);

            my $char = substr $solution, $char_cnt, 1;
            $txt->translate( $x + ( $sq_size / 2 ),
                $y - ( $sq_size / 2 ) - ( $font_size / 2 ) + 2 );
            if ( $char ne q{.} ) {
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
print timestr( $timer_diff, 'all' ) or croak;
print "\n\n" or croak;


__END__
my$j = 0;
for my $i (0..$document_length) {
    my $char = substr ($document, $i, 1);
    if ($char ne "\n") {
        $j++;
    }
    print "$i .. $char .. $j\n";
}
