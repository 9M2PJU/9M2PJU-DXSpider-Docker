#
# show dx (normal)
#
#
#

my ($self, $line) = @_;
my @list = split /\s+/, $line;	# split the line up

my @out;
my $f;
my $call;
my ($from, $to);
my ($fromday, $today);
my @freq;
my @ans;
my $pre;
my $spotter;
my $info;
my $expr;
my $hint;
my $dxcc;
my $real;
my $zone;
my $byzone;
my $state;
my $bystate;
my $itu;
my $byitu;
my $fromdxcc = 0;
my $exact;
my $origin;
my $ip;
my ($doqsl, $doiota, $doqra, $dofilter);

my $usesql = $main::dbh && $Spot::use_db_for_search;

while ($f = shift @list) {		# next field
	dbg "arg: $f list: " . join(',', @list) if isdbg('shdx');
	if (!$from && !$to) {
		($from, $to) = $f =~ m|^(\d+)[-/](\d+)$|; # is it a from -> to count?
		next if $from && $to > $from;
	}
	if (!$to) {
		($to) = $f =~ /^(\d+)$/o if !$to; # is it a to count?
		next if $to;
	}
	if (lc $f eq 'exact') {
		$exact = 1;
		next;
	}
	if (lc $f eq 'dxcc') {
		$dxcc = 1;
		next;
	}
	if (lc $f eq 'rt' || $f =~ /^real/i) {
		$real = 1;
		next;
	}
	if (lc $f eq 'on' && $list[0]) { # is it freq range?
		dbg "freq $list[0]" if isdbg('shdx');
		if (my ($from, $to) = $list[0] =~ m|^(\d+)(?:\.\d+)?(?:[-/](\d+)(?:\.\d+)?)?$|) {
			$to = $from unless defined $to;
			dbg "freq '$from' '$to'" if isdbg('shdx');
			push @freq, $from, $to;
			shift @list;
			next;
		} else {
			my @r = split '/', lc $list[0];
			dbg "r0: $r[0] r1: $r[1]" if isdbg('shdx');
			my @fr = Bands::get_freq($r[0], $r[1]);
			if (@fr) {			# yup, get rid of extranous param
				dbg "freq: " . join(',', @fr) if isdbg('shdx');
				push @freq, @fr;    # add these to the list
				shift @list;
				next;
			}
		}
	}
	if (lc $f eq 'day' && $list[0]) {
		($fromday, $today) = split m|[-/]|, shift(@list);
		dbg "got day $fromday/$today" if isdbg('shdx');
		next;
	}
	if (lc $f eq 'info' && $list[0]) {
		$info = shift @list;
		dbg "got info $info" if isdbg('shdx');
		next;
	}
	if (lc $f eq 'origin' && $list[0]) {
		$origin = uc shift @list;
		dbg "got origin $origin" if isdbg('shdx');
		next;
	}
	if (lc $f eq 'ip' && $list[0]) {
		$ip = shift @list;
		dbg "got ip $ip" if isdbg('shdx');
		next;
	}

	if ((lc $f eq 'spotter' || lc $f eq 'by') && $list[0]) {
		$spotter = uc shift @list;
		if ($list[0] && lc $list[0] eq 'dxcc') {
			$fromdxcc = 1;
			shift @list;
		}
		dbg "got spotter $spotter fromdxcc $fromdxcc" if isdbg('shdx');
		next;
	}
	if (lc $f =~ /^filt/) {
		$dofilter = 1 if $self && $self->spotsfilter;
		next;
	}
	if (lc $f eq 'qsl') {
		$doqsl = 1;
		next;
	}
	if (lc $f eq 'iota') {
		my ($a, $b);
#		$DB::single =1;
		
		if (@list && $list[0] && (($a, $b) = $list[0] =~ /(AF|AN|NA|SA|EU|AS|OC)-?(\d?\d\d)/oi)) {
			$a = uc $a;
			$doiota = "\\b$a\[\-\ \]\?$b\\b";
			shift @list;
		}
		$doiota = '\b(IOTA|(AF|AN|NA|SA|EU|AS|OC)[- ]?\d?\d\d)\b' unless $doiota;
		next;
	}
	if (lc $f eq 'qra') {
		$doqra = uc shift @list if @list && $list[0] =~ /[A-Z][A-Z]\d\d/oi;
		$doqra = '\b([A-Z][A-Z]\d\d|[A-Z][A-Z]\d\d[A-Z][A-Z])\b' unless $doqra;
		next;
	}
	if (lc $f eq 'zone') {
		$zone = shift @list if @list;
		next;
	}
	if (lc $f =~ /^by_?zone/) {
		$byzone = shift @list if @list;
		next;
	}
	if (lc $f eq 'itu') {
		$itu = shift @list if @list;
		next;
	}
	if (lc $f =~ /^by_?itu/) {
		$byitu = shift @list if @list;
		next;
	}
	if (lc $f eq 'state') {
		$state = uc shift @list if @list;
		next;
	}
	if (lc $f =~ /^by_?state/) {
		$bystate = uc shift @list if @list;
		next;
	}
	if (!$pre) {
		$pre = uc $f;
	}
}

#$DB::single = 1;

# check origin
if ($origin) {
	$expr .= ' && ' if $expr;
	$expr .= "\$f7 eq '$origin'";
	$hint .= ' && ' if $hint;
	$hint .= "m{$origin}";
}

# check (any) ip address
if ($ip) {
	$expr .= ' && ' if $expr;
	$expr .= "\$f14 && \$f14 =~ m{^$ip}";
	$hint .= ' && ' if $hint;
	$ip =~ s/\./\\./g;			# IPV4
	$hint .= "m{$ip}";
}

#  deal with the prefix
if ($pre) {
	my @ans;
	
	if ($dxcc) {
		@ans = Prefix::extract($pre);	# is it a callsign/prefix?
		
		if (@ans) {

			# first deal with the prefix
			my $pre = shift @ans;
			my $a;
			my $str = "Prefix: $pre";
			my $l = length $str;
			my @expr;
			my @hint;
			
			# build up a search string for this dxcc country/countries
			foreach $a (@ans) {
				my $n = $a->dxcc();
			    push @expr, "\$f5 == $n";
				push @hint, "m{$n}";
				my $name = $a->name();
				$str .= " Dxcc: $n ($name)";
				push @out, $str;
				$str = ' ' x $l;
			}
			$expr = @expr > 1 ? '(' . join(' || ', @expr) . ')' : $expr[0];
			$hint = @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
		}
	} 
	unless (@ans) {
		$pre .= '*' unless $pre =~ /[\*\?\[]$/o;
		$pre = shellregex($pre);
		if ($usesql) {
			$pre =~ s/\.\*/%/g;
		} else {
			$pre =~ s/\.\*\$$//;
		}
		$pre .= '$' if $exact;
		$expr = "\$f1 =~ m{$pre}";
		$pre =~ s/[\^\$]//g;
		$hint = "m{\U$pre}";
	}
}
  
# now deal with any frequencies specified
if (@freq) {
	$expr .= ($expr) ? ' && (' : "(";
#	$hint .= ($hint) ? ' && ' : "(";
#	$hint .= ' && ' if $hint;
	my $i;
	for ($i = 0; $i < @freq; $i += 2) {
		$expr .= "(\$f0 >= $freq[$i] && \$f0 <= $freq[$i+1]) ||";
		my $r = Spot::ftor($freq[$i], $freq[$i+1]);
#		$hint .= "m{$r\\.} ||" if $r;
#		$hint .= "m{\d+\.} ||";
#		$hint .= "1 ||";
	}
	chop $expr;	chop $expr;
#	chop $hint;	chop $hint;
	$expr .= ")";
#	$hint .= ")";
}

# any info
if ($info) {
	$expr .= ' && ' if $expr;
#	$info =~ s{(.)}{"\Q$1"}ge;
	$expr .= "\$f3 =~ m{$info}i";
	$hint .= ' && ' if $hint;
	$hint .= "m{$info}i";
}

# any spotter
if ($spotter) {
	
	if ($fromdxcc) {
		@ans = Prefix::extract($spotter);	# is it a callsign/prefix?
		
		if (@ans) {

			# first deal with the prefix
			my $pre = shift @ans;
			my $a;
			$expr .= ' && ' if $expr;
			$hint .= ' && ' if $hint;
			my $str = "Spotter: $pre";
			my $l = length $str;
			my @expr;
			my @hint;
			
			# build up a search string for this dxcc country/countries
			foreach $a (@ans) {
				my $n = $a->dxcc();
			    push @expr, "\$f6 == $n";
				push @hint, "m{$n}";
				my $name = $a->name();
				$str .= " Dxcc: $n ($name)";
				push @out, $str;
				$str = ' ' x $l;
			}
			$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : $expr[0];
			$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
		}
	} 
	unless (@ans) {
		$expr .= ' && ' if $expr;
		$spotter .= '*' unless $spotter =~ /[\*\?\[]/o;
		$spotter = shellregex($spotter);
		if ($usesql) {
			$spotter =~ s/\.\*/%/g;
		} else {
			$spotter =~ s/\.\*\$$//;
		}
		$expr .= "\$f4 =~ m{\U$spotter}";
		$hint .= ' && ' if $hint;
		$spotter =~ s/[\^\$]//g;
		$hint .= "m{\U$spotter}";
	}
}

# zone requests
if ($zone) {
	my @expr;
	my @hint;
	$expr .= ' && ' if $expr;
	$hint .= ' && ' if $hint;
	for (split /[:,]/, $zone) {
		push @expr, "\$f9==$_";
		push @hint, "m{$_}";
	}
	$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : $expr[0];
	$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
}
if ($byzone) {
	my @expr;
	my @hint;
	$expr .= ' && ' if $expr;
	$hint .= ' && ' if $hint;
	for (split /[:,]/, $byzone) {
		push @expr, "\$f11==$_";
		push @hint, "m{$_}";
	}
	$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : $expr[0];
	$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
}

# itu requests
if ($itu) {
	my @expr;
	my @hint;
	$expr .= ' && ' if $expr;
	$hint .= ' && ' if $hint;
	for (split /[:,]/, $itu) {
		push @expr, "\$f8==$_";
		push @hint, "m{$_}";
	}
	$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : $expr[0];
	$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
}
if ($byitu) {
	my @expr;
	my @hint;
	$expr .= ' && ' if $expr;
	$hint .= ' && ' if $hint;
	for (split /[:,]/, $byitu) {
		push @expr, "\$f10==$_";
		push @hint, "m{$_}";
	}
	$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : $expr[0];
	$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
}

# state requests
if ($state) {
	my @expr;
	my @hint;
	$expr .= ' && ' if $expr;
	$hint .= ' && ' if $hint;
	for (split /[:,]/, $state) {
		push @expr, "\$f12 eq '$_'";
		push @hint, "m{$_}";
	}
	if ($usesql) {
		$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : "$expr[0]";
	} else {
		$expr .= @expr > 1 ? '(\$f12 && (' . join(' || ', @expr) . '))' : "(\$f12 && $expr[0])";
	}
	$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
}
if ($bystate) {
	my @expr;
	my @hint;
	$expr .= ' && ' if $expr;
	$hint .= ' && ' if $hint;
	for (split /[:,]/, $bystate) {
		push @expr, "\$f13 eq '$_'";
		push @hint, "m{$_}";
	}
	if ($usesql) {
		$expr .= @expr > 1 ? '(' . join(' || ', @expr) . ')' : "$expr[0]";
	} else {
		$expr .= @expr > 1 ? '(\$f13 && (' . join(' || ', @expr) . '))' : "(\$f13 && $expr[0])";
	}
	$hint .= @hint > 1 ? '(' . join(' || ', @hint) . ')' : $hint[0];
}

# qsl requests
if ($doqsl) {
	$expr .= ' && ' if $expr;
	$expr .= "\$f3 =~ m{QSL|VIA}i";
	$hint .= ' && ' if $hint;
	$hint .= "m{QSL|VIA}i";
}

# iota requests
if ($doiota) {
	$expr .= ' && ' if $expr;
	$expr .= "\$f3 =~ m{$doiota}i";
	$hint .= ' && ' if $hint;
	$hint .= "m{$doiota}i";
}

# iota requests
if ($doqra) {
	$expr .= ' && ' if $expr;
	$expr .= "\$f3 =~ m{$doqra}i";
	$hint .= ' && ' if $hint;
	$hint .= "m{$doqra}io";
}

$from ||= '';
$to ||= '';
$fromday ||= '';
$today ||= '';

dbg "expr: $expr from: $from to: $to fromday: $fromday today: $today" if isdbg('sh/dx');
  
# now do the search
my @res = Spot::search($expr, $fromday, $today, $from, $to, $hint, $dofilter ? $self : undef);
my $ref;
my @dx;
foreach $ref (@res) {
	if ($self && $self->ve7cc) {
		push @out, VE7CC::dx_spot($self, @$ref);
	} else {
		if ($self && $real) {
			push @out, DXCommandmode::format_dx_spot($self, @$ref);
		} else {
			push @out, Spot::formatl(@$ref);
		}
	}
}

return (1, @out);
