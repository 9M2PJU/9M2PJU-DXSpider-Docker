#
# print out the wwv stats
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
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
$to = 5 unless $to;

push @out, $self->msg('wwv3');
my @in = Geomag::search($from, $to, $main::systime);
for (@in) {
	push @out, Geomag::print_item($_);
}
return (1, @out);
