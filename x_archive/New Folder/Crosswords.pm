package Crosswords;

use strict;
use warnings;
use Readonly;
use English qw( -no_match_vars );
use Carp;

use base qw(Exporter);

use vars qw ( $VERSION );

use version; our $VERSION = q{0.00001};

our @EXPORT_OK = qw(
    get_output_file_name
    check_for_check_string
    get_day_from_title
    get_sunday_theme
    get_sunday_title
    get_puzzle_width
    get_puzzle_height
    get_number_of_clues
    get_document
    get_solution
    get_grid
    get_clue_string_array
    get_title
    get_author
    get_copyright
    get_note
    get_circles
    get_rebus
    generate_sunday_puzzle
    generate_daily_puzzle
);

sub generate_sunday_puzzle {
    print "SUNDAY\n";
}

sub generate_daily_puzzle {
    print "DAILY\n";
    
    my ($arg_ref) = @_;
    print $arg_ref, "\n";
    my $w = $arg_ref->{width};
    print $w, "\n";
}

sub get_rebus_table {
    my $document = shift;
    Readonly my $SKIP => 4;
    my $index;
    if (0) {
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
            my $char = substr $document, $index, 1;
            #print $char, "\n" or croak;
        }
    }
    return;
    }
}

sub get_rebus {
    my $document = shift;
    my %rebus;
    my $index;
    Readonly my $SKIP => 4;
    Readonly my $FOUND => -1;

    if ( index( $document, q{GRBS} ) != $FOUND) {
        $index = index $document, q{GRBS};
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

        #blow past checksum
        $index += 2;

        for my $i ( 0 .. ($l + 1) ) {
            $index++;
            my $char = substr $document, $index, 1;
            if ( ord $char > 0 ) {
                $rebus{$i} = 1;
            }
        }
    }
    return %rebus;
}

sub get_circles {
    my $document = shift;
    my %circles;
    my $index;
    Readonly my $SKIP => 4;
    Readonly my $FOUND => -1;

    if ( index( $document, q{GEXT} ) != $FOUND ) {
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
        for my $i ( 0 .. $l-1 ) {
            $index++;
            my $char = substr $document, $index, 1;
            if ( substr( unpack( 'B8', $char ), 0, 1 ) eq '1' ) {
                $circles{$i} = 1;
            }
        }
    }
    return %circles;
}

sub get_title {
    my $strings_ref = shift;
    return shift $strings_ref;
}

sub get_author {
    my $strings_ref = shift;
    return shift $strings_ref;
}

sub get_copyright {
    my $strings_ref = shift;
    return shift $strings_ref;
}

sub get_note {
    my $strings_ref = shift;
    my $num_strings = shift;
    my $num_clues = shift;

    my $note = q{};
    if ( $num_strings - $num_clues ) {
        $note = pop $strings_ref;
        #chop off the terminating null char
        chop $note;
    }
    return $note;
}

sub get_clue_string_array {
    my $doc = shift;
    my $squares = shift;
    my $num_clues = shift;

    Readonly my $HDR_STRINGS => 4;

    Readonly my $OFFSET => 52;
    my $offset = $OFFSET + $squares + $squares;

    my $str      = q{};
    my $char     = q{};
    my $line_cnt = 0;
    my @strings  = ();
    while ( $line_cnt < $num_clues + $HDR_STRINGS ) {
        $char = substr $doc, $offset, 1;
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
    return @strings;
}

sub get_grid {
    my $doc = shift;
    my $squares = shift;

    Readonly my $OFFSET => 52;

    my $offset = $OFFSET + $squares;
    return substr $doc, $offset, $squares;
}


sub get_solution {
    my $doc = shift;
    my $squares = shift;

    Readonly my $OFFSET => 52;
    return substr $doc, $OFFSET, $squares;
}

sub get_document {
    my $file = shift;

    open my $IN, '<', $file or croak;
    binmode $IN;
    my $document = do {
        local $INPUT_RECORD_SEPARATOR = undef;
        <$IN>;
    };
    close $IN or croak;
    return $document;
}

sub get_number_of_clues {
    my $doc = shift;

    Readonly my $C1 => 46;
    my $c1 = substr $doc, $C1, 2;
    my $l_str = sprintf q{%02x}, ord $c1;
    return hex $l_str;
}

sub get_puzzle_width {
    my $doc = shift;
    Readonly my $OFFSET => 44;
    return ord substr $doc, $OFFSET, 1;
}

sub get_puzzle_height {
    my $doc = shift;
    Readonly my $OFFSET => 45;
    return ord substr $doc, $OFFSET, 1;
}

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

sub get_day_from_title {
    my $title = shift;
    my $day;
    if ( $title =~ m{NY\sTimes,\s(.*)day}ixms ) {
        $day = $1;
        $day .= q{day};
    } 
    else {
        croak "Unable to determine the day on this puzzle\n$title\n";
    }
    return $day;
}

sub check_for_check_string {
    my $doc = shift;
    Readonly my $OFFSET => 2;
    Readonly my $LENGTH => 11;

    my $str = substr $doc, $OFFSET, $LENGTH;
    chomp $str;
    if ( $str eq 'ACROSS&DOWN' ) {
        return 1;
    }
    return 0;
}

sub get_output_file_name {
    my $f = shift;

    if ( $f =~ m{(.*)[.]puz}ixms ) {
        return $1 . '.pdf';
    }

}
###########################
###########################
1;
