# 
# echo the line passed to the output decoding certain 
# "escape" sequences on the way
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;

$line =~ s/\\t/\t/g;			# tabs
$line =~ s/\\a/\a/g;			# beeps
my @out = split /\\[n]/, $line;
return (1, @out);
