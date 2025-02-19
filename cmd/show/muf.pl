#!/usr/bin/perl
#
# show/muf command
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
# as fixed by Steve Franke K9AN
#
#
#

use Minimuf;

my ($self, $line) = @_;
my @f = split /\s+/, $line;

my $prefix = uc shift @f;
return (1, $self->msg('e4')) unless $prefix;
my $lp;
my $hr2;

while (@f) {
	my $f = shift @f;
	$lp++ if $f =~ /^l/;
	$hr2 = $f if $f =~ /^\d+$/;
}

$hr2 = 2 if !$hr2 || $hr2 < 2;
$hr2 = 24 if $hr2 > 24;

my @out;

# get prefix data
my ($pre, $a) = Prefix::extract($prefix);

# calc bearings and distance
my ($d, $b1, $b2);				# distance, bearing from TX and from RX
my ($lat2, $lon2);              # lats and longs in radians
my $lat1 = $self->user->lat;
my $lon1 = $self->user->long;
my $loc1 = $self->user->qth || "unknown";

if (!$lon1 && !$lat1) {
	push @out, $self->msg('heade1');
	$lat1 = $main::mylatitude;
	$lon1 = $main::mylongitude;
	$loc1 = $main::myqth;
}
$lat2 = $a->{lat};
$lon2 = $a->{long};
($b1, $d) = DXBearing::bdist($lat1, $lon1, $lat2, $lon2);	
($b2, undef) = DXBearing::bdist($lat2, $lon2, $lat1, $lon1);

# convert stuff into radians
$lat1 *= $d2r;
$lat2 *= $d2r;
$lon1 *= -$d2r;
$lon2 *= -$d2r;
$b1 *= $d2r;
$b2 *= $d2r;
$d = ($d / $R);

# handle long path
if ($lp) {
	$d = $pi2 - $d;
	$b1 += $pi;
	$b1 -= $pi2 if ($b1 >= $pi2);
	$b2 += $pi;
	$b2 -= $pi2 if ($b2 >= $pi2);
}


my ($hr1, $day, $month) = (gmtime($main::systime))[2,3,4];
$month++;
my $flux = Geomag::sfi;
my $ssn = Minimuf::spots($flux);

my $theta;						# path angle (rad) 
$theta=$lon1-$lon2;
$theta=$theta+2.*$pi if( $theta <= -$pi);
$theta=$theta-2.*$pi if( $theta >= $pi);

my ($lats, $lons);				# subsolar coordinates (rad) 
my $dB1 = 26;					# transmitter output power (dBW) 

my $delay;						# path delay (ms) 
my $psi;						# sun zenith angle (rad) 
my ($ftemp, $gtemp);			# my $temps 
my ($i, $j, $h, $n);			# int temps 
my $offset;						# offset for local time (hours) 
my $fcF;						# F-layer critical frequency (MHz) 
my $phiF;						# F-layer angle of incidence (rad) 
my $hop;						# number of ray hops 
my $beta1;						# elevation angle (rad) 
my $dhop;						# hop great-circle distance (rad) 
my $height;						# height of F layer (km) 
my $time;						# time of day (hour) 
my $rsens = -128;				# RX sensitivity


my @freq = qw(1.8 3.5 7.0 10.1 14.0 18.1 21.0 24.9 28.0 50.0); # working frequencies (MHz) 
my $nfreq = @freq;				# number of frequencies 
my @mufE;						# maximum E-layer MUF (MHz) 
my @mufF;						# minimum F-layer MUF (MHz) 
my @absorp;						# ionospheric absorption coefficient 
my @dB2;						# receive power (dBm) 
my @path;						# path length (km) 
my @beta;						# elevation angle (rad) 
my @daynight;					# path flags 	

# calculate hops, elevation angle, F-layer incidence, delay.
$hop = int ($d / (2 * acos($R / ($R + $hF))));
$beta1 = 0;
while ($beta1 < $MINBETA) {
	$hop++;
	$dhop = $d / ($hop * 2);
	$beta1 = atan((cos($dhop) - $R / ($R + $hF)) / sin($dhop));
}
$ftemp = $R * cos($beta1) / ($R + $hF);
$phiF = atan($ftemp / sqrt(1 - $ftemp * $ftemp));
$delay = ((2 * $hop * sin($dhop) * ($R + $hF)) / cos($beta1) / $VOFL) * 1e6;

# print summary of data so far
push @out, sprintf("RxSens: $rsens dBM SFI:%4.0f   R:%4.0f   Month: $month   Day: $day", $flux, $ssn);
push @out, sprintf("Power :  %3.0f dBW    Distance:%6.0f km    Delay:%5.1f ms", $dB1, $d * $R, $delay);
push @out, sprintf("Location                       Lat / Long           Azim");
push @out, sprintf("%-30.30s %-18s    %3.0f", $loc1, DXBearing::lltos($lat1*$r2d, -$lon1*$r2d), $b1 * $r2d);
push @out, sprintf("%-30.30s %-18s    %3.0f", $a->name, DXBearing::lltos($lat2*$r2d, -$lon2*$r2d), $b2 * $r2d);
my $head = "UT LT  MUF Zen";
for ($i = 0; $i < $nfreq; $i++) {
	$head .= sprintf "%5.1f", $freq[$i];
}
push @out, $head;

my $hour;

# Hour loop: This loop determines the min-hop path and next two
# higher-hop paths. It selects the most likely path for each
# frequency and calculates the receive power. The F-layer
# critical frequency is computed directly from MINIMUF 3.5 and
# the secant law.

$offset = int ($lon2 * 24. / $pi2);
for ($hour = $hr1; $hour < $hr2+$hr1; $hour++) {
    my $dh = $hour;
	while ($dh >= 24) {
		$dh -= 24;
	};
	$time = $dh - $offset;
	$time += 24 if ($time < 0);
	$time -= 24 if ($time >= 24);
	my $out = sprintf("%2.0f %2.0f", $dh, $time);
	$ftemp = Minimuf::minimuf($flux, $month, $day, $dh, $lat1, $lon1, $lat2, $lon2);
	$fcF = $ftemp * cos($phiF);
	
	# Calculate subsolar coordinates.
	$ftemp = ($month - 1) * 365.25 / 12. + $day - 80.;
	$lats = 23.5 * $d2r * sin($ftemp / 365.25 * $pi2);
	$lons = ($dh * 15. - 180.) * $d2r;
	
	# Path loop: This loop determines the geometry of the
	# min-hop path and the next two higher-hop paths. It
	# calculates the minimum F-layer MUF, maximum E-layer
	# MUF and ionospheric absorption factor for each
	# geometry.
	for ($h = $hop; $h < $hop + 3; $h++) {
		
		# We assume the F layer height increases during
		# the day and decreases at night, as determined
		# at the midpoint of the path.
		$height = $hF;
		$psi = Minimuf::zenith($d / 2, $lat1, $lon1, $b1, $theta, $lats, $lons);
		if ($psi < 0) {
			$height -= 70.;
		} else {
			$height += 30;
		}
		$dhop = $d / ($h * 2.);
		$beta[$h] = atan((cos($dhop) - $R / ($R + $height)) / sin($dhop));
		$path[$h] = 2 * $h * sin($dhop) * ($R + $height) / cos($beta[$h]);
		Minimuf::ion($h, $d, $fcF, $ssn, $lat1, $lon1, $b1, $theta, $lats, $lons, \@daynight, \@mufE, \@mufF, \@absorp);
	}
	
	# Display one line for this hour.
	$out .= sprintf("%5.1f%4.0f ", $mufF[$hop], 90 - $psi * $r2d);
	$ftemp = $noise;
	for ($i = 0; $i < $nfreq; $i++) {
		$n = Minimuf::pathloss($hop, $freq[$i], 20, $rsens, 0,  \@daynight, \@beta, \@path, \@mufF, \@mufE, \@absorp, \@dB2);
		my $s = Minimuf::ds($n, $rsens, \@dB2, \@daynight);
		$out .= " $s"; 
	}
	$out =~ s/\s+$//;
	push @out, $out;
}

return (1, @out);
