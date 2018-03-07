#!/usr/bin/perl


use Carp;
use warnings;
use strict;
use POSIX;
use PDF::API2;



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

my $str = 'rsm1';
while ( my $bytesRead = ( read $IN, $buffer, 1 ) ) {
    
    substr($str, 0, 1) = substr($str, 1, 1);
    substr($str, 1, 1) = substr($str, 2, 1);
    substr($str, 2, 1) = substr($str, 3, 1);
    substr($str, 3, 1) = $buffer;
    print $str, "--------------------------\n";
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
            }
            
        }
    }
}
