#
# do an HFSpot table 
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#
# Modified on 2002/10/27 by K1XX for his own use
# Valid inputs (and then tarted up by G1TLH to include in the
# main distribution):
#
# sh/hftable (original operation, starts from today for own prefix)
#
# sh/hftable [<date>] [<no. of days>] [prefix] [prefix] [prefix] ..
#
# sh/hftable [<date>] [<no. of days>]  (data from your own prefix)
# 
# sh/hftable [<date>] [<no. of days>] [callsign] [callsign] [callsign] ..
#
# sh/hftable [<date>] [<no of days>] all
#  
#
# Known good data formats
# dd-mmm-yy
# 24-Nov-02 (using - . or / as separator)
# 24nov02 (ie no separators)
# 24nov2002
#
# mm-dd-yy (this depends on your locale settings)
# 11-24-02 (using - . or / as separator) 
#
# yymmdd
# 021124
# 20021124
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @calls;
my $days = 31;
my @dxcc;
my $limit = 100;
my %list;
my $i;
my $now;
my @pref;
my @out;
my $date;
my $all;

#$DB::single = 1;

while (@f) {
	my $f = shift @f;

	if ($f =~ /^\d+$/ && $f < 366) {		# no of days
		$days = $f;
		next;
	}
	if (my $utime = Date::Parse::str2time($f)) {	# is it a parseable date?
		$utime += 3600;
		$now = Julian::Day->new($utime);
		$date = cldate($utime);
		next;
	}
	$f = uc $f;
	if (is_callsign($f)) {
		push @dxcc, [$f, 0];
		push @pref, $f;
	} else {
		if ($f eq 'ALL' ) {
			$all++;
			push @pref, $f;
			next;
		}
		if (my @ciz = Prefix::to_ciz('nc', $f)) {
			push @dxcc, map {[$_, 2]} @ciz;
			push @pref, $f;
		} else {
			push @out, $self->msg('e27', $f);
		}
	}
}

# return error messages if any
return (1, @out) if @out;

# default prefixes
unless (@pref) {					# no prefix or callsign, use default prefix
	push @dxcc, [$_, 2] for @main::my_cc;
	push @pref, $main::mycall;
}

# default date
unless ($now) {
	$now = Julian::Day->new(time); #no starting date
	$date = cldate(time);
}

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
		next if $l[0] eq 'TOTALS';
		next unless $all || grep $l[$_->[1]] eq $_->[0], @dxcc;
		my $ref = $list{$l[0]} || [0,0,0,0,0,0,0,0,0,0];
		my $j = 1;
		foreach my $item (@l[4..13]) {
			$ref->[$j] += $item;
			$ref->[0] += $item;
			$j++;
		}
		$list{$l[0]} = $ref if $ref->[0];
	}
	$now = $now->sub(1);
}

my @tot;
my $nocalls;

my $l = join ',', @pref;
push @out, $self->msg('stathft', $l, $date, $days);
push @out, sprintf "%9s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|%5s|", qw(Callsign Tot 160m 80m 60m 40m 30m 20m 17m 15m 12m 10m);

for (sort {$list{$b}->[0] <=> $list{$a}->[0] || $a cmp $b} keys %list) {
	my $ref = $list{$_};
	$nocalls++;
	my @list = (sprintf "%9s", $_);
	foreach my $j (0..11) {
		my $r = $ref->[$j];
		if ($r) {
			$tot[$j] += $r;
			$r = sprintf("%5d", $r);
		} else {
			$r = '     ';
		}
		push @list, $r;
	}
	push @out, join('|', @list);
	last if $limit && $nocalls >= $limit;
}

$nocalls = sprintf "%9s", "$nocalls calls";
@tot = map {$_ ?  sprintf("%5d", $_) : '     ' } @tot;
push @out, join('|', $nocalls, @tot,"");

return (1, @out);
