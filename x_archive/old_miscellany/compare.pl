#!/usr/bin/perl

use strict;
use warnings;

my $str = '00001111';
my $cmp = '00011000';

if ($str & $cmp) {
    print "OK\n";
}


print chr(0x80);
print chr(65);

print unpack('B8', chr(0x80));

print "\n\n\n";

if (substr( unpack('B8', chr(0x80)), 0, 1) eq '1') {
    print "circle\n";
}
