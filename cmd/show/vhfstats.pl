#
# Show total VHF DX Spot Stats per day
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $days = 31;
my $i;
my @in;
my $now;
my $date = cldate($main::systime);
my $utime = $main::systime;
my @out;

while (@f) {
	my $f = shift @f;

	if ($f =~ /^\d+$/ && $f < 366) {		# no of days
		$days = $f;
		next;
	}
	if (my $ut = Date::Parse::str2time($f)) {	# is it a parseable date?
		$utime = $ut+3600;
		next;
	}
	push @out, $self->msg('e33', $f);
}

return (1, @out) if @out;

$now = Julian::Day->new($utime);
$now = $now->sub($days);
$date = cldate($utime);

# generate the spot list
for ($i = 0; $i < $days; $i++) {
	my $fh = $Spot::statp->open($now); # get the next file
	unless ($fh) {
		Spot::genstats($now);
		$fh = $Spot::statp->open($now);
	}
	while (<$fh>) {
		chomp;
		my @l = split /\^/;
		next unless $l[0] eq 'TOTALS';
		next unless $l[1];
		$l[0] = $now; 
		push @in, \@l; 
		last;
	}
	$now = $now->add(1);
}

my @tot;

push @out, $self->msg('statvhf', $date, $days);
push @out, sprintf "%11s|%6s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|", qw(Date Total 6m 4m 2m 70cm 23cm 13cm 9cm 6cm 3cm);
foreach my $ref (@in) {
	my $linetot = 0;
	foreach my $j (14..16,18..23) {
		$tot[$j] += $ref->[$j];
		$tot[0] += $ref->[$j];
		$linetot += $ref->[$j];
	}
	push @out, join('|', sprintf("%11s|%6d", $ref->[0]->as_string, $linetot), map {$_ ? sprintf("%5d", $_) : '     '} @$ref[14..16,18..23]) . '|';
}
push @out, join('|', sprintf("%11s|%6d", 'Total', $tot[0]), map {$_ ? sprintf("%5d", $_) : '     '} @tot[14..16,18..23]) . '|';

return (1, @out);
