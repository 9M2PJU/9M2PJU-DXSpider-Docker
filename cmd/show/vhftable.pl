#
# do an VHFSpot table 
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
		foreach my $item (@l[14..16, 18..23]) {
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
push @out, $self->msg('statvhft', $l, $date, $days);
#push @out, $self->msg('statvhft', join(',', @dxcc), cldate(time));
push @out, sprintf "%10s|%4s|%4s|%4s|%4s|%4s|%4s|%4s|%4s|%4s|%4s|", qw(Callsign Tot 6m 4m 2m 70cm 23cm 13cm 9cm 6cm 3cm);

for (sort {$list{$b}->[0] <=> $list{$a}->[0] || $a cmp $b} keys %list) {
	my $ref = $list{$_};
	$nocalls++;
	my @list = (sprintf "%10s", $_);
	foreach my $j (0..9) {
		my $r = $ref->[$j];
		if ($r) {
			$tot[$j] += $r;
			$r = sprintf("%4d", $r);
		} else {
			$r = '    ';
		}
		push @list, $r;
	}
	push @out, join('|', @list, "");
	last if $limit && $nocalls >= $limit;
}

$nocalls = sprintf "%10s", "$nocalls calls";
@tot = map {$_ ?  sprintf("%4d", $_) : '    ' } @tot;
push @out, join('|', $nocalls, @tot, "");

return (1, @out);
