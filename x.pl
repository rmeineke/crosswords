#!/usr/bin/perl

use warnings;
use strict;
use Carp;
use POSIX;
use PDF::API2;
use English qw( -no_match_vars );
use Text::Format;

use Readonly;

use Benchmark;

use Getopt::Long;

our $VERSION = 0.00003;

Readonly my $COLUMN_WIDTH      => 125;
Readonly my $COLUMN_HEIGHT     => 720;
Readonly my $MAX_HEIGHT        => 1650;
Readonly my $SUNDAY_MAX_HEIGHT => 1950;

Readonly my $NUM_SHORT_COLS   => 3;

Readonly my $TWO_DIGITS => 99;

#this next one should be max width ....
#2/13/2018 was not square ... it was 16 tall by 15 wide...
#since it was taller .. the three clue columns above it should be
#a bit shorter than usual
Readonly my $MAX_GRID_SIZE => 405;
Readonly my $LGE_GRID_FONT => 8;
Readonly my $SM_GRID_FONT => 6;

Readonly my $STD_FONT => 14;

#2018.02.18 I broke this ... by starting the font at 10!
Readonly my $SUNDAY_FONT => 8;
Readonly my $MIN_FONT => 6;

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
    my $tmp   = q{};
    if ( $title =~ m{(^.*\d\d\d\d).*}ixms ) {
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
    if ( $title =~ m{.*\d\d\d\d(.*)}ixms ) {
        $theme = $1;
    }

    #strip off any spaces
    $theme =~ s{^\s}{}ixms;
    $theme =~ s{\s$}{}ixms;

    return $theme;
}

sub carve_up_long_string {

    #print "carve_up_long_string() called\n";
    #this is the entire clue payload
    #dumped into one long string
    my $str = shift;

    print $str, "\n" or croak;

    #passed in the day in case it was
    #sunday ... to save some cycles through
    #the font processing
    my $day = shift;

    my $max_height = $MAX_HEIGHT;
    if ( $day eq 'Sunday' ) {
        $max_height = $SUNDAY_MAX_HEIGHT;
    }
    print "max_height == $max_height\n" or croak;


    #this works .... if it doesn't break anything else
    #2018.02.15
    #here was an edge case for 2018.02.13 ... one row higher than wide
    #caused the clues to overlap onto the grid
    my $width = shift;
    my $height = shift;
    if ($height > $width) {
        my $diff = $height - $width;
        print "diff >>>>>>>>>>>>>>>>>>>>>>>> $diff\n"
    }
    my $adj = int($MAX_GRID_SIZE / $width);
    $max_height -= $adj;
    print "max_height == $max_height\n" or croak;

    #replace any dashes w/ '-|'
    $str =~ s{-}{-|}gixms;

    #replace any slashes w/ '/|'
    $str =~ s{\/}{\/|}gixms;

    #the last one screws up dates
    #10/|20/|1968
    #
    #this will cobble any dates back together
    #it might need some tweaking later
    #
    # s:(\d+)\/\|(\d+)\/\|(\d\d\d\d):$1/$2/$3:g
    $str =~ s{(\d\d)\/\|(\d\d)\/\|(\d\d\d\d)}{$1/$2/$3}gixms;

    print $str or croak;

    #now the words are broken out into an array
    #spiltting on the pipe character and the space
    #this should retain any hyphens and slashes
    my @words = split /[|\s]/ixms, $str;

    print "\n\nJOIN\n";
    print join q{,}, @words or croak;

    my $pdf  = PDF::API2->new();
    my $page = $pdf->page;
    my %font
        = (
        Times => { Roman => $pdf->corefont( 'Times', -encoding => 'latin1' ) }
        );

    my $txt = $page->text;
    my @temp_words;
    my $str_font = $STD_FONT;
    if ( $day eq 'Sunday' ) {
        $str_font = $SUNDAY_FONT;
    }

    print "str_font = $str_font\n" or croak;

    my $end_font;
#    my $height       = 0;
    my $minimum_font = $MIN_FONT;

    #process the strings through each font size
    for ( my $i = $str_font; $i > $minimum_font; $i-- ) {

        print "Checking font size: $i\n" or croak;
        #set the font
        $txt->font( $font{'Times'}{'Roman'}, $i );

        #reset the temp array
        @temp_words = ();

        my $temp_str = q{};

        my $num_words = @words;

        #print $num_words, " == num_words\n" or croak;

        #while the length is still less than one column wide (125pts)
        #add the next word to the end and test again
        my $new_str;

        for ( my $i = 0; $i < $num_words; $i++ ) {
            #if the next 'word' is just the clue number
            #the last string needs to be pushed onto
            #the stack
            #
            #added the '$' terminator here ... 2/27/2018
            #had an edge case that caused a minor formatting issue
            # "Org. with a 3.4-ounce container rule"
            if ( $words[$i] =~ m/\d+\.$/ixms and $i != 0 ) {
                print " ///////////////// >$words[$i]<\n";
                # ///////////////// >3.4-<
                push @temp_words, $temp_str;
                $temp_str = q{};
            }

            if ( int( $txt->advancewidth($temp_str) ) > $COLUMN_WIDTH ) {
                print "need to fix a really long word";
                print "$temp_str\n"
            }

            $new_str      = $temp_str;
            $temp_str = $temp_str . q { } . $words[$i];
            
            #remove leading space
            $temp_str =~ s{^\s}{}ixms;
            
            #remove spaces after any dashes
            $temp_str =~ s{-\s}{-}ixms;

            #remove spaces after slashes
            $temp_str =~ s{\/\s}{\/}ixms;

            #insert a space
            $temp_str =~ s{(\d)-and}{$1- and}ixms;
            $temp_str =~ s{(\d)-to}{$1- to}ixms;
            $temp_str =~ s{(\d)-or}{$1- or}ixms;
            
            #>>>>>26. Shot- to- the- solar-<<<<<
            #>>>>>plexus sound<<<<<
            # a letter 
            # a dash 
            # a space
            # a letter
            if ($temp_str =~ m{[A-Za-z]-\s[A-Za-z]}ixms) {
                $temp_str =~ s{([A-Za-z]-)\s([A-Za-z])}{$1$2}gixms;
            }
            
            # a number 
            # a dash 
            # a space 
            # and the word Down
            if ($temp_str =~ m{\d*-\sDown}ixms) {
                $temp_str =~ s{(\d*-)\s(Down)}{$1$2}ixms;
            }
        
            # a number 
            # a dash 
            # a space 
            # and the word Across
            if ($temp_str =~ m{\d*-\sAcross}ixms) {
                $temp_str =~ s{(\d*-)\s(Across)}{$1$2}ixms;
            }

            if ( $temp_str =~ m{DOWN}xms ) {
                push @temp_words, q{[[BLANK]]};
            }
            $temp_str =~ s/999\.\s//ixms;

            if ($DEBUG) {
                print int( $txt->advancewidth($temp_str) ), q{ -- >>},
                $temp_str, qq{<<\n}
                or croak;
            }

            my $new_temp_str;
            if ( $temp_str =~ m{\d+\.\s}ixms ) {
                $new_temp_str = $temp_str;
            }
            else {
                #pad the string to account for the indent
                $new_temp_str = q{      } . $temp_str;
            }

            if ( int( $txt->advancewidth($new_temp_str) ) > $COLUMN_WIDTH ) {
                #print "I'm breaking here ... $new_temp_str\n";
                $i--;
                push @temp_words, $new_str;
                $temp_str = q{};
            }
        }
        print "pushing: $temp_str\n";
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
my $start_time = Benchmark->new;
if ( $#ARGV != 0 ) {
    print "Usage:\tx.pl filename\n" or croak;
    print "\tx.pl Aug2613.puz\n"  or croak;
    print "-d for debugging\n" or croak;
    print "-h for rebus hints\n" or croak;
    print "-s for the solution\n" or croak;
    print "\n" or croak;
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

    #should we make a pdf for this?
}

$offset = 44;
my $width = ord substr $document, $offset, 1;
print $width, " == width \n" or croak;

$offset++;
my $height = ord substr $document, $offset, 1;
print $height, " == height \n" or croak;

my $squares = $width * $height;
print $squares, " == squares\n" or croak;

$offset++;
my $num_clues = substr $document, $offset, 1;
$offset++;
$num_clues .= substr $document, $offset, 1;
$num_clues = ord $num_clues;

print $num_clues, "\n" or croak;

$offset = 52;
my $solution;
if ($SOLVE) {
    $solution = substr $document, $offset, $squares;
    if ($DEBUG) {
        print "============ SOLUTION ===================\n" or croak;
        print $solution, "\n" or croak;
        my $j = 0;
        for my $i (0 .. $height) {
            print substr $solution, $j, $width or croak;
            print "\n" or croak;
            $j += $width;
        }
        print "============ SOLUTION ===================\n" or croak;
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
    for my $i (0 .. $height) {
        print substr $grid, $j, $width or croak;
        print "\n" or croak;
        $j += $width;
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
for my $i (0 .. $height) {
    $matrix[$i][0] = q{.};
}

for my $i (0 .. $width) {
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
    for my $i (0 .. $height) {
        for my $j (0 .. $width) {
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
    if ( $char eq qq{\0} ) {
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

#2018.02.18 ... the title on sunday puzzles has now been shortened from "Sunday" to "Sun"
#new:
#NY Times, Sun, Feb 18, 2018 SEE 68-ACROSS
#old:
#NY Times, Sunday, September 1, 2013 Persons Of Note
if ( $title =~ m/sun/ixms ) {
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
print "Num clue strings == $num_strings\n" or croak;

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


# if there is a section of extra info it should be here
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
if ( index( $document, q{GEXT} ) != -1 ) {
    $index = index $document, q{GEXT};
    print "GEXT FOUND ..... $index\n" or croak;

    #hop past the 'GEXT' in the document
    $index = $index + $SKIP;

    #grab next 2 bytes and make them a
    #string ... then see what the ordinal
    #is ... should be the length of the
    #circle data info
    my $c2 = substr $document, $index, 1;
    $index++;
    my $c1 = substr $document, $index, 1;
    my $l_str = sprintf q{%02x%02x}, ord $c1, ord $c2;
    my $l = hex $l_str;
    print "CIRCLE LENGTH == $l\n" or croak;

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

            #print "CIRCLE ---> $i\n" or croak;
        }
    }
}

my %rebus;
if ($HINT) {
    if ( index( $document, q{GRBS} ) != -1 ) {
        $index = index $document, q{GRBS};
        print "GRBS FOUND ..... $index\n" or croak;

        #hop past the 'GRBS' in the document
        $index = $index + $SKIP;

        #grab next 2 bytes and make them a
        #string ... then see what the ordinal
        #is ... should be the length of the
        #circle data info
        my $c2 = substr $document, $index, 1;
        $index++;
        my $c1 = substr $document, $index, 1;
        my $l_str = sprintf q{%02x%02x}, ord $c1, ord $c2;
        my $l = hex $l_str;
        print "REBUS LENGTH == $l\n" or croak;

        #blow past checksum
        $index += 2;

        for my $i ( 0 .. ($l + 1) ) {
            $index++;
            $char = substr $document, $index, 1;
            if ( ord $char > 0 ) {
                $rebus{$i} = 1;
            }
        }
    }
}

#REBUS Table
if ($HINT) {
    if ( index( $document, q{RTBL} ) != -1 ) {
        $index = index $document, q{RTBL};
        print "RTBL FOUND ..... $index\n" or croak;

        #hop past the 'RTBL' in the document
        $index = $index + $SKIP;

        #grab next 2 bytes and make them a
        #string ... then see what the ordinal
        #is ... should be the length of the
        #rebus table data info
        my $c2 = substr $document, $index, 1;
        $index++;
        my $c1 = substr $document, $index, 1;
        my $l_str = sprintf q{%02x%02x}, ord $c1, ord $c2;
        my $l = hex $l_str;
        print "REBUS Table LENGTH == $l\n" or croak;

        #blow past checksum
        $index += 2;

        for my $i (0 .. ($l + 1)) {
            $index++;
            $char = substr $document, $index, 1;
            #print $char, "\n" or croak;
        }
    }
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
    for my $i (1 .. $height) {
        for my $j (1 .. $width) {
            print $matrix[$i][$j] or croak;
        }
        print "\n" or croak;
    }
    print "\n\n\n" or croak;
}

if ($DEBUG) {
    print "\n\n\n" or croak;
    for my $i (0 .. $height) {
        for my $j (0 .. $width) {
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

my @across;
my @down;

#parse the clues and then separate them into across and down
for my $i (1 .. $height) {
    for my $j (1 .. $width) {
        next if $matrix[$i][$j] eq q{.};
      
        my $a = 0;
        my $d = 0;

        #any position and preceded by a dot (.)
        if ( $matrix[$i][$j] eq q{y} && $matrix[$i][ ( $j - 1 ) ] eq q{.} ) {
            $num_across++;
            $a++;
            push @clue_order, 'a';
            
            #Nov 20 2013 one off issue ...
            #had two downs with no across clues
            #
            #according to those in the know: these
            #are called 'unchecked squares' as there
            #is no adjoining square with which to validate
            #the entry by checking the across clues
            if ($j != $width) {
            if ($matrix[$i][ ( $j + 1 ) ] eq q{.}) {
                $num_across--;
                $a--;
                pop @clue_order;
            }
            }   
            if ($j == $width) {
                $num_across--;
                $a--;
                pop @clue_order;
            }
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
    print qq{\n\n}                                    or croak;
    print "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD\n" or croak;
    print join q{,}, @down or croak;
    print qq{\n\n} or croak;
}

$num_across = @across;
$num_down   = @down;
my $ttl_clues = $num_across + $num_down;

print $ttl_clues, " == ttl_clues\n\n" or croak;

my $three_digit_across = 0;
my $three_digit_down   = 0;
if ( $across[ $num_across - 1 ] > $TWO_DIGITS ) {
    #print "There are triple digit ACROSS clues in this puzzle\n" or croak;
    $three_digit_across++;
}

if ( $down[ $num_down - 1 ] > $TWO_DIGITS ) {
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
for my $i (0 .. ($length - 1)) {
    $across_list[$i] = "$across[$i]." . q{ } . "$across_list[$i]";
}
unshift @across_list, q{999. ::ACROSS:::::::};

$length = @down_list;

#this will prepend the clue number
#to the front of the clue
for my $i (0 .. ($length -1)) {
    $down_list[$i] = "$down[$i]. $down_list[$i]";
}
unshift @down_list, q{999. ::DOWN:::::::};

#put a gap between the acrosses and the downs
unshift @down_list, q{          };

my @clue_list = ( @across_list, @down_list );
if ($DEBUG) {
    foreach my $c (@clue_list) {
        print $c, "\n" or croak;
    }
}

my $long_str = q{};
foreach my $c (@clue_list) {
    my @words = split m/\s+/ixms, $c;
    foreach my $w (@words) {
        chomp $w;

        #need a check here for any super-long words here
        #
        #edge case from .... 2018.01.25
        #had one long word (Polytetrafluoroethylene,), that was always longer than
        #the column was wide.
        #
        #if a super-long word is found, ideally it would be
        #hyphenated ... but until I can figure out how best to
        #do that we'll just hack it in half and push the
        #halves on the long string
        if (length $w > 20) {
            print " ------------> $w\n";
            my $half = ((length $w) / 2);
            print $half, "\n";
            my $str1 = '';
            exit;
        }
        $long_str = $long_str . q{ } . $w;
    }
}

#can I use height / width here?
print "////////////////////////////////\n";
print "$height\n";
print "$width\n";
print "////////////////////////////////\n";
# as it turns out, yes.
# passing them in for a heretofore undiscovered edge case
# height was one line more than the width ... which pushed
# the grid up into the clue list on the 3 short lists
$long_str =~ s{^\s+}{}ixms;
my ( $font_size, $ttl_height, @shortened_clue_list )
    = carve_up_long_string( $long_str, $day, $width, $height );

if ($DEBUG) {
    for my $w (@shortened_clue_list) {
        print q{>>>>>}, $w, qq{<<<<<\n} or croak;
    }
}

#rsm
#ttl_height is calculated in the carve up long string
print $ttl_height, " == ttl_height\n" or croak;
my $col_height = ceil( ( $ttl_height - $COLUMN_HEIGHT ) / $NUM_SHORT_COLS );
print $col_height, " == 2nd/3rd/4th\n" or croak;

#print '$day == ' . $day . "\n" or croak;
#print "\n$font_size\n\n" or croak;
my $proper_font_size = $font_size;

#this makes the grid_size dynamic
my $grid_font = $LGE_GRID_FONT;
my $grid_size = ceil( $COLUMN_HEIGHT - $col_height );
if ( $grid_size > $MAX_GRID_SIZE ) {
    $grid_size = $MAX_GRID_SIZE;
}
if ( $grid_size < $MAX_GRID_SIZE ) {
    $grid_font = $SM_GRID_FONT;
}

if ($DEBUG) {
    print $grid_size, " == grid_size\n" or croak;
    print $grid_font, " == grid_font\n" or croak;
}




#print $proper_font_size, " <----- font\n" or croak;
my $lines = @shortened_clue_list;

print $lines, " lines in clue list\n" or croak;

###################################
# set up the clue columns here

my $line_spacing = 2;

#number of clue lines in the first column
my $first_col = ceil( $COLUMN_HEIGHT / ( $proper_font_size + $line_spacing ) );
print ">>>>>>>  $shortened_clue_list[$first_col   - 1]\n";
print $first_col, " first_col\n" or croak;
my $rem = $lines - $first_col;

my $second_col = ceil( $rem / $NUM_SHORT_COLS );
print $second_col, " second_col\n" or croak;

my $third_col  = $second_col;
print $third_col, " third_col\n" or croak;

my $fourth_col = $rem - $second_col - $third_col;
print $fourth_col, " fourth_col\n" or croak;

my $checklines = $first_col + $second_col + $third_col + $fourth_col;
print $checklines, " checklines\n" or croak;
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





my @columns = ( $first_col, $second_col, $third_col, $fourth_col );
my @first_lines = (
    0, $first_col,
    $first_col + $second_col,
    $first_col + $second_col + $third_col,
);

print "===========================\n" or croak;
for my $i (1..3) {

    if ($shortened_clue_list[$first_lines[$i]] !~ m{^\s*\d+\.\s}ixms) {
        print "ORPHAN ... \n" or croak;
        #$shortened_clue_list[$first_lines[$i] - 1] .= q{ ->};
    }
}
print "===========================\n" or croak;

my @col_x = ( 36, 171, 306, 441 );
my @col_y = ( 756, 756, 756, 756 );

for my $col (0..3) {
    print "\n\n" or croak;
    printf ("%-5s  %-12s  %-10s  %-10s\n", "col #", "columns[col]", "col_x[col]", "col_y[col]") or croak;
    print "-----  ------------  ----------  ----------\n" or croak;
    printf ("%-6s %-13s %-11s %-10s\n", $col, $columns[$col], $col_x[$col], $col_y[$col]) or croak;
    print "\n" or croak;

    my $st_x = $col_x[$col];
    my $st_y = $col_y[$col];
    $txt->translate( $st_x, $st_y );

    my $first_line = $first_lines[$col];
    my $last_line  = $first_line + $columns[$col];

    print $first_line, " first_line\n" or croak;
    print $last_line, " last_line\n" or croak;
    my $top_line   = 1;
    if ($shortened_clue_list[$first_line] =~ m{BLANK}xms) {
            print "BLANK FOUND\n";
            $last_line++;
            $first_lines[2]++;
            $first_lines[3]++;
            #$columns[2]--;
            $columns[3]--;
    }
    
    for my $i ($first_line.. ($last_line -1)) {
        next if $shortened_clue_list[$i] =~ m{BLANK}xms and $i == $first_line;

        #set proper font_size;
        $txt->font( $font{'Times'}{'Roman'}, $proper_font_size );
        $txt->fillcolor('#000000');

        my $output = $shortened_clue_list[$i];
        if ($three_digit_across) {

            #no digits found at the beginning are a line continuation
            #therefore, indent w/ spaces
            #see the note below about the ^\d edge case ....


            if ( $output !~ m{^\d+\.}ixms ) {
                $output = q{        } . $output;
            }

            #single digit clue
            if ( $output =~ m{^\d\.\s}ixms ) {
                $output = q{    } . $output;
            }

            #double digit clue
            if ( $output =~ m{^\d\d\.\s}ixms ) {
                $output = q{  } . $output;
            }

            if ( $output =~ m{[[BLANK]]}xms ) {
                $output = q{  };
            }

            if ( $output =~ m{ACROSS}xms ) {
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
            #2018.01.03 ... fixed an edge case w/ the ^\d
            if ( $output !~ m{^\d+\.}ixms ) {
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
        
if (0) {
        #>>>>>26. Shot- to- the- solar-<<<<<
        #>>>>>plexus sound<<<<<
        if ($output =~ m{[A-Za-z]-\s[A-Za-z]}ixms) {
            print "FOUND IT .............................\n";
            $output =~ s{([A-Za-z]-)\s([A-Za-z])}{$1$2}gixms;
        }
        
        if ($output =~ m{\d*-\sDown}ixms) {
            $output =~ s{(\d*-)\s(Down)}{$1$2}ixms;
            print $output, "\n\n";
        }
    
        if ($output =~ m{\d*-\sAcross}ixms) {
            $output =~ s{(\d*-)\s(Across)}{$1$2}ixms;
            print $output, "\n\n";
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

print "$width .... width\n"   or croak;
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





#shaded boxes ....................................
#lightened up ........ 2014.09.09
my $box = $page->gfx;
$box->fillcolor('#aFaFaF');

#my $height = $width;
my $count = 0;
my $x;
my $y;
my $st_x;
my $st_y;





#are there any circles to draw?
#
# shifted this up so that the clue numbers
# are not obliterated by the circles when
# drawn
#
if (%circles) {
    my $circle = $page->gfx;

    #line width?
    #this seems to work
    $circle->linewidth(0.5);
    $circle->strokecolor('#ff0000');
    # can this be more transparent?
    #$circle->transparency(0.5);

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    my $circle_cnt = -1;

    for my $i ( 0 .. ( $height - 1 ) ) {
        for my $j ( 0 .. ( $width - 1 ) ) {
            $circle_cnt++;
            if ( $circles{$circle_cnt} ) {
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

#start the text .........
$txt = $page->text;
$txt->font( $font{'Times'}{'Roman'}, $grid_font );
$txt->fillcolor('#000000');

#fill the gray boxes....
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
for my $i (0..($height -1)) {
    $y = $st_y - ( ( $i + 1 ) * $sq_size );
    for my $j (0..($width-1)) {
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
for my $i (0..($height -1)) {
    $y = $st_y - ( ($i) * $sq_size );
    for my $j (0..($width - 1)) {
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
$line->linewidth(.1);
$line->strokecolor('#000000');

#upperleft of the grid
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
$line->move( $st_x, $st_y );

#horizontal
for my $i (0..$height) {
    $line->line( $st_x + $box_size_width, $st_y );
    $line->stroke;

    $st_y -= $sq_size;
    $line->move( $st_x, $st_y );
}

#vertical
$st_y = $box_upper_left_y;
$st_x = $box_upper_left_x;
$line->move( $st_x, $st_y );

for my $i (0..$width) {
    $line->line( $st_x, $st_y - $box_size_height );
    $line->stroke;

    $st_x += $sq_size;
    $line->move( $st_x, $st_y );
}

my $txt2 = $page->text;
$txt2->font( $font{'Times'}{'Bold'}, 8 );
$txt2->fillcolor('#000000');

#$title = $title . "    [$proper_font_size]";
my $l = int( $txt2->advancewidth($title) );

#$txt2->translate( (578 - $l - $box_size_difference), $reference_corner_y - 10 + $box_size_difference );

$txt2->translate( $reference_corner_x - $l, $reference_corner_y - 8 );
$txt2->text($title);


#2017.12.30 >>>>>>>>>>>>>>
#$note = "40 characters mmmmmmmmmmmmmmmmmmmmmmmmmm";
#$note = "50 characters mmmmmmmmmmmmmmmmmmmmmmmmmm     xxxxx";
if ( $note ne q{} ) {
    if (length $note > 40) {
        print "..... need 2nd page for long note here \n";
        my $page2 = $pdf->page;
        my $txt_pg2 = $page2->text;
        $txt_pg2->font( $font{'Times'}{'Roman'}, 16 );
        $txt_pg2->fillcolor('#000000');
        my $pg2_x = 72;
        my $pg2_y = 720;
        $txt_pg2->translate($pg2_x, $pg2_y);
        
        #my $pdf  = PDF::API2->new();
        #my $page = $pdf->page;
        my $wrap = Text::Format->new({columns => 60});
        my @txt_strings = $wrap->format($note);
        foreach my $string (@txt_strings) {
            $txt_pg2->text($string);
            $pg2_y -= 20;
            $txt_pg2->translate($pg2_x, $pg2_y);
        }
        #$txt_pg2->text($note);
    } else {
        my $note_x = $box_upper_left_x;
        my $note_y = $reference_corner_y - 8;
        $txt->font( $font{'Times'}{'Roman'}, 8 );
#        print "note_x --> $note_x\n";
#        print "note_y --> $note_y\n";
#        $txt->translate( $note_x, ( $note_y ) );
#        $txt->font( $font{'Times'}{'Bold'}, 8 );
#        $txt->text($note);

        #added this ... to highlight the sunday theme
        my $text_background = $page->gfx(1);
        my $txt_length = int( $txt->advancewidth($note) );
        my $bgd_rect = $text_background->rect( ($note_x - 1), ($note_y - 2), ($txt_length + 2), 9);
        $bgd_rect->fillcolor('#f0f000');
        $bgd_rect->fill;

        $txt->translate( $note_x, $note_y);
        $txt->fillcolor('#000000');
        $txt->text($note);
    }
}

#are there any REBUS to draw?
if ( %rebus && $HINT ) {
    print "About to draw the REBUS hints\n" or croak;
    my $rebus_txt      = $page->text;
    my $eg_trans = $pdf->egstate();
    if ($DEBUG) {
        $eg_trans->transparency(0.5);
        $rebus_txt->fillcolor('#ff0000');
    } else {
        $eg_trans->transparency(0.9);
        $rebus_txt->fillcolor('#0000ff');
    }
    $rebus_txt->font( $font{'Times'}{'Roman'}, $sq_size );
    $rebus_txt->egstate($eg_trans);

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    #print "$x .. $y <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n" or croak;
    my $rebus_cnt = -1;

    #print "$width x $height >>>>>>>>>>>>>>>>>>>>>\n" or croak;
    for my $i ( 1 .. $height ) {
        for my $j ( 1 .. $width ) {
            $rebus_cnt++;

            #print "$i x $j\n" or croak;
            if ( $rebus{$rebus_cnt} ) {
                $rebus_txt->translate( $x + ( .25 * $sq_size ), $y - ($sq_size) );
                $rebus_txt->text(q{*});
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
    my $sol_txt       = $page->text;
    my $sol_font_size = ceil($sq_size) - 4;

    print $sol_font_size, " == sol_font_size .... solution\n" or croak;

    my $eg_trans = $pdf->egstate();
    $eg_trans->transparency(0.2);
    $sol_txt->egstate($eg_trans);

    $sol_txt->font( $font{'Times'}{'Roman'}, $sol_font_size );
    $sol_txt->fillcolor('#1E90FF');

    $y = $box_upper_left_y;
    $x = $box_upper_left_x;

    my $sol_char_cnt = -1;

    for my $i ( 1 .. $height ) {
        for my $j ( 1 .. $width ) {
            $sol_char_cnt++;
            my $sol_char = substr $solution, $sol_char_cnt, 1;
            $sol_txt->translate( $x + ( $sq_size / 2 ),
                $y - ( $sq_size / 2 ) - ( $sol_font_size / 2 ) + 2 );
            if ( $sol_char ne q{.} ) {
                $sol_txt->text_center($sol_char);
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
print "\n\n" or croak;
print timestr( $timer_diff, 'all' ) or croak;
print "\n\n" or croak;
__END__
