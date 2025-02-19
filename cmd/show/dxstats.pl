#
# Show total DXStats per day
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @calls;
my $days = 31;
my @dxcc;
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

my $tot;

push @out, $self->msg('statdx', $date, $days);
foreach my $ref (@in) {
	push @out, sprintf "%12s: %7d", $ref->[0]->as_string, $ref->[1];
	$tot += $ref->[1];
}
push @out, sprintf "%12s: %7d", "Total", $tot;

return (1, @out);
