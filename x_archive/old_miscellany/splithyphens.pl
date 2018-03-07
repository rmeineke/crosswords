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

my $str = "Hammer-on-the-thumb cries";

$str =~ m/(.*)-(.*)/;
print $1, "\n";
print $2, "\n";


print $1 . '- ' . $2, "\n";
