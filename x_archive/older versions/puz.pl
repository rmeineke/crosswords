#!/usr/bin/perl

use Carp;
use warnings;
use strict;

my $file_in = "puz.puz";
open my $IN, '<', $file_in or croak;

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

#next grouping is solution
my @sol;

foreach (my $i = 0; $i < $characters; $i++) {
    read $IN, $buffer, 1;
    push @sol, $buffer;
}


print "******************************\n";


my $count = 0;
for (my $i = 0; $i < $characters; $i++) {
    $count++;
    print $sol[$i];
    if ($count == $width) {
        print "\n";
        $count = 0;
    }
}   


#next grouping is grid
my @grid;

foreach (my $i = 0; $i < $characters; $i++) {
    read $IN, $buffer, 1;
    push @grid, $buffer;
}


print "*****************************\n";


$count = 0;
for (my $i = 0; $i < $characters; $i++) {
    $count++;
    print $grid[$i];
    if ($count == $width) {
        print "\n";
        $count = 0;
    }
}   

my @notes;
while (read $IN, $buffer, 1) {
	#print (">", ord($buffer), "<\n");
	if (ord($buffer) == 0) {
		push @notes, "\n";
    } else {
		#print ">$buffer<";
		push @notes, $buffer;
	}
}

my $l = @notes;
print $l, "\n";
print @notes;
close $IN;
