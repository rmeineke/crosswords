#!/usr/bin/perl

use Carp;
use warnings;
use strict;


sub is_word_start {
    my $i =     
    return 1;
}

my $file_in = "puz.puz";
open my $IN, '<', $file_in or croak;

binmode($IN);

my $bytesRead;
my $buffer;


seek $IN, 0x2c, 0;
read $IN, $buffer, 2;

my $width = ord substr $buffer, 0, 1;
my $height = ord substr $buffer, 1, 1;

print $width . " x " . $height . "\n";

my $characters = $width * $height;
print "Num characters == $characters\n";

read $IN, $buffer, 2;

my $num_clues = ord $buffer;
print "Num clues == $num_clues\n";


#skip next 4
read $IN, $buffer, 4;

#solution
read $IN, $buffer, 225;

my @matrix;
for (my $i = 0; $i < $height; $i++) {
    for (my $j = 0; $j < $width; $j++) {
        read $IN, $buffer, 1;
        my $str = $buffer;
        $matrix[$i][$j] = $str;
    }
}

my $num_squares = 0;
for (my $i = 0; $i < $height; $i++) {
    for (my $j = 0; $j < $width; $j++) {
        next if $matrix[$i][$j] eq '.';
        if ($i == 0 || $matrix[($i - 1)][$j] eq '.') {        
            $matrix[$i][$j] = 'y';
            $num_squares++;
        }
        if ($j == 0 || $matrix[$i][($j - 1)] eq '.' && $matrix[$i][$j] ne 'y') {
            $matrix[$i][$j] = 'y';
            $num_squares++;
        }
    }
}


if (0) {
for (my $j = 0; $j < $width; $j++) {
    for (my $i = 0; $i < $height; $i++) {
        next if ($matrix[$i][$j] eq '.' || $matrix[$i][$j] eq 'y');
        if ($j == 0 || $matrix[$i][($j - 1)] eq '.') {
            $matrix[$i][$j] = 'y';
            $num_squares++;
        }
    }
}
}#########3

print "num_squares == ", $num_squares, "\n";
print "\nMATRIX:::\n";
for (my $i = 0; $i < $height; $i++) {
    for (my $j = 0; $j < $width; $j++) {
        print $matrix[$i][$j];
    }
    print "\n";
}
#-------------------------------------------------

my $str = '';
my @strings;
while (my $bytesRead = (read $IN, $buffer, 1) ) {
    $str .= $buffer;
    if ($buffer eq "\0") {
        push @strings, $str;
        $str = '';
    }
}
my $title = shift @strings;
my $author = shift @strings;
my $copyright = shift @strings;

my $num_strings = @strings;
print "Num strings == $num_strings\n";

if ($strings[$num_strings - 1] eq "\0") {
    print "__$strings[$num_strings - 1]__\n";
    pop @strings;
}


$num_strings = @strings;
print "Num strings == $num_strings\n";

print "__$strings[$num_strings - 1]__\n";


close $IN;
__END__
if (0) {
for (my $j = 0; $j < $width; $j++) {
    for (my $i = 0; $i < $height; $i++) {
        next if ($matrix[$i][$j] eq '.' || $matrix[$i][$j] eq 'y');
        if ($j == 0 || $matrix[$i][($j - 1)] eq '.') {
            $matrix[$i][$j] = y;
            $num_squares++;
        }
    }
}
}
