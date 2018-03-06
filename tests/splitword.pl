#!/usr/bin/perl -w

sub splitword{
    my $lw = shift;
    my $a = 'a';
    my $b = 'b';

    print "splitting: $lw\n";
    return $a, $b;
}

my @str = qw{one two three areallyfreakinglongtextherez};



for my $w (@str) {
    print $w, "\n";
    if (length $w > 20) {
        print length $w;
        my ($a, $b) = splitword($w);
        print $a, "\n";
        print $b, "\n";
    }
}