#
# print out the wcy stats
#
# Copyright (c) 2000 - Dirk Koopman G1TLH
#
#
#
my $self = shift;

my $cmdline = shift;
my @f = split /\s+/, $cmdline;
my $f;
my @out;
my ($from, $to); 

$from = 0;
while ($f = shift @f) {                 # next field
	#  print "f: $f list: ", join(',', @list), "\n";
	if (!$from && !$to) {
		($from, $to) = $f =~ /^(\d+)-(\d+)$/o;         # is it a from -> to count?
		next if $from && $to > $from;
	}
	if (!$to) {
		($to) = $f =~ /^(\d+)$/o;              # is it a to count?
		next if $to;
	}
}

$from = 1 unless $from;
$to = 10 unless $to;

push @out, $self->msg('wcy3');
my @in = WCY::search($from, $to, $main::systime);
for (@in) {
	push @out, WCY::print_item($_);
}
return (1, @out);












