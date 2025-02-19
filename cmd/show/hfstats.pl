#
# Show total HF DX Spot Stats per day
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#
# Modified on 2002/10/29 by K1XX for his own use
# Valid inputs:
#
# sh/hfstats
#
# sh/hfstats <date> <no. of days>
#
# Known good data formats
# dd-mmm-yy
# 24-Nov-02 (using - . or / as separator)
#
# mm-dd-yy
# 11/24/02 (using - . or / as separator)
#
# yymmdd
# 021124
#

use Date::Parse;

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

push @out, $self->msg('stathf', $date, $days);
push @out, sprintf "%6s|%6s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|", qw(Date Total 160m 80m 60m 40m 30m 20m 17m 15m 12m 10m);
foreach my $ref (@in) {
	my $linetot = 0;
	foreach my $j (4..13) {
		$tot[$j] += $ref->[$j];
		$tot[0] += $ref->[$j];
		$linetot += $ref->[$j];
	}
	my $date = $ref->[0]->as_string;
	$date =~ s/-\d+$//;
	push @out, join '|', sprintf("%6s|%6d", $date, $linetot), map {$_ ? sprintf("%5d", $_) : '     '} @$ref[4..13], "";
}
push @out, join '|', sprintf("%6s|%6d", 'Total', $tot[0]), map {$_ ? sprintf("%5d", $_) : '     '} @tot[4..13], "";

return (1, @out);
