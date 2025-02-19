#
# the DX command
#
# this is where the fun starts!
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line, 3;
my $spotter = $self->call;
my $spotted;
my $freq;
my @out;
my $valid = 0;
my $localonly;
my $oline = $line;

#$DB::single=1;

return (1, $self->msg('e5')) if $self->remotecmd || $self->inscript;
return (1, $self->msg('e28')) unless $self->isregistered;


my $addr = $self->hostname || '127.0.0.1';
Log('cmd', "$self->{call}|$addr|dx|$line");

my @bad;
if (@bad = BadWords::check($line)) {	
	$self->badcount(($self->badcount||0) + @bad);
	LogDbg('DXCommand', "$self->{call} swore: $line (with words:" . join(',', @bad) . ")");
	$localonly++; 
}

# do we have at least two args?
return (1, $self->msg('dx2')) unless @f >= 2;

# as a result of a suggestion by Steve K9AN, I am changing the syntax of
# 'spotted by' things to "dx by g1tlh <freq> <call>" <freq> and <call>
# can be in any order

if ($f[0] =~ /^by$/i) {
	return (1, $self->msg('e5')) unless $main::allowdxby || $self->priv > 1;
    $spotter = uc $f[1];
    $line =~ s/^\s*$f[0]\s+$f[1]\s+//;
	@f = split /\s+/, $line, 3; 
	return (1, $self->msg('dx2')) unless @f >= 2;
}

my $ipaddr;
@f = split /\s+/, $line, 3;
if ($f[0] eq 'ip') {
	return (1, $self->msg('e5')) unless $spotter &&  $self->priv > 1;
	if (is_ipaddr($f[1])) {
		$ipaddr = $f[1];
	} else {
		return (1, $self->msg('dx4', $f[1]));
	}
	$line =~ s/^\s*$f[0]\s+$f[1]\s+//;
	@f = split /\s+/, $line, 3;
}


# get the freq and callsign either way round
if (is_freq($f[1]) && $f[0] =~ m{^[\w\d]+(?:/[\w\d]+){0,2}$}) {
	$spotted = uc $f[0];
	$freq = $f[1];
} elsif (is_freq($f[0]) && $f[1] =~ m{^[\w\d]+(?:/[\w\d]+){0,2}$}) {
    $freq = $f[0];
	$spotted = uc $f[1];
} else {
	return (1, $self->msg('dx3'));
}
$line =~ s/^\s*$f[0]//;
$line =~ s/^\s*$f[1]//;
$line =~ unpad($line);
$line =~ s/\t+/ /g;				# do this here because it needs to be stopped ASAP!
$line ||= ' ';

if ($self->conn && $self->conn->peerhost) {
	$ipaddr ||= $addr; # force a PC61 
} elsif ($self->inscript) {
	$ipaddr = "script";
}

# check some other things
# remove ssid from calls
my $spotternoid = basecall($spotter);
my $callnoid = basecall($self->{call});

#$DB::single = 1;

if ($DXProt::baddx->in($spotted)) {
	++$localonly; 
}
if ($DXProt::badspotter->in($spotternoid)) { 
	LogDbg('DXCommand', "badspotter $spotternoid as $spotter ($oline) from $ipaddr");
	++$localonly; 
}
if ($ipaddr && DXCIDR::find($ipaddr)) {
	LogDbg('DXCommand', "Bad IP address $ipaddr $spotternoid as $spotter ($oline)");
	++$localonly; 
}

#dbg "spotter $spotternoid/$callnoid\";

if (($spotted =~ /$spotternoid/ || $spotted =~ /$callnoid/) && $freq < $Spot::minselfspotqrg) {
	LogDbg('DXCommand', "$spotternoid/$callnoid trying to self spot below ${Spot::minselfspotqrg}KHz ($oline) from $addr, not passed on to cluster");
	$localonly++;
}

# bash down the list of bands until a valid one is reached
my $bandref;
my @bb;
my $i;

# first in KHz
L1:
foreach $bandref (Bands::get_all()) {
	@bb = @{$bandref->band};
	for ($i = 0; $i < @bb; $i += 2) {
		if ($freq >= $bb[$i] && $freq <= $bb[$i+1]) {
			$valid = 1;
			last L1;
		}
	}
}

unless ($valid) {

	# try again in MHZ 
	$freq = $freq * 1000 if $freq;

 L2:
    foreach $bandref (Bands::get_all()) {
		@bb = @{$bandref->band};
		for ($i = 0; $i < @bb; $i += 2) {
			if ($freq >= $bb[$i] && $freq <= $bb[$i+1]) {
				$valid = 1;
				last L2;
			}
		}
	}
}


push @out, $self->msg('dx1', $freq) unless $valid;

# check we have a callsign :-)
if ($spotted le ' ') {
	push @out, $self->msg('dx2');
	$valid = 0;
}

return (1, @out) unless $valid;

# Store it here (but only if it isn't baddx)
my $t = (int ($main::systime/60)) * 60;
return (1, $self->msg('dup')) if Spot::dup($freq, $spotted, $t, $line, $spotter, $main::mycall);
my @spot = Spot::prepare($freq, $spotted, $t, $line, $spotter, $main::mycall, $ipaddr);

#$DB::single = 1;

if ($freq =~ /^69/ || $localonly) {

	# heaven forfend that we get a 69Mhz band :-)
	if ($freq =~ /^69/) {
		$self->badcount(($self->badcount||0) + 1);
	}

	$self->dx_spot(undef, undef, @spot);

	return (1);
} else {
	# send orf to the users
	$ipaddr ||= $main::mycall;	# emergency backstop
	my $spot = DXProt::pc61($spotter, $freq, $spotted, unpad($line),  $ipaddr);
	
	$self->dx_spot(undef, undef, @spot);
	if ($self->isslugged) {
		push @{$self->{sluggedpcs}}, [61, $spot, \@spot];
	} else {
		# store in spots database 
		Spot::add(@spot);
		DXProt::send_dx_spot($self, $spot, @spot);
	}
}

return (1, @out);



