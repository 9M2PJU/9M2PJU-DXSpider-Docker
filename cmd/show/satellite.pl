#!/usr/bin/perl
#
# show satellite az/el 
#
# copyright (c) 1999 Steve Franke K9AN
#
#
# 
# 2001/12/16 added age of keps in the sh/sat output list.
#   Note - there is the potential for problems when satellite name
#   is longer than 20 characters. The list shows only the 
#   first 20 chars, so user won't know the full name.
#   So far, it seems that only the GPS sats even come close... 

my ($self, $line) = @_;
my @out;

my @f = split /\s+/, $line;
my $satname = uc shift @f if @f;
my $numhours = shift @f if @f;	# the number of hours ahead to print
my $step = shift @f if @f;		# tracking table resolution in minutes

# default hours and step size
$numhours = 3 unless $numhours && $numhours =~ /^\d+$/;
$numhours = 3 if $numhours < 0;
$numhours = 24 if $numhours > 24;
$step = 5 unless $step && $step =~ /^\d+$/;
$step = 5 if $step < 0;
$step = 30 if $step > 30;

# get nearest lat and long (I can see we will need the altitude here soon as well :-)
my $lat = $self->user->lat;
my $lon = $self->user->long;
my $alt = 0;
my $call = $self->call;
unless ($lon || $lat) {
	$lat = $main::mylatitude;
	$lon = $main::mylongitude;
	$call = $main::mycall;
}

my $jtime; # lats and longs in radians
my ($sec, $min, $hr, $day, $mon, $yr) = (gmtime($main::systime))[0,1,2,3,4,5];
#printf("%2.2d %2.2d %2.2d %2.2d %2.2d\n",$min,$hr,$day,$mon,$yr);

$mon++;
$yr += 1900;

$jtime=Sun::Julian_Day($yr,$mon,$day)+$hr/24+$min/60/24;

#$DB::single=1;
if ($satname && $Sun::keps{$satname}) {

	($yr,$mon,$day,$hr,$min)=Sun::Calendar_date_and_time_from_JD($jtime);
	#printf("%2.2d %2.2d %2.2d %2.2d %2.2d\n",$min,$hr,$day,$mon,$yr);
	push @out, $self->msg("pos", $call, slat($lat), slong($lon));
	push @out, $self->msg("sat1", $satname, $numhours, $step);
	push @out, $self->msg("sat2");
	
	my ($slat,$slon,$salt,$az,$el,$distance)=Sun::get_satellite_pos($jtime,$lat*$d2r,$lon*$d2r,$alt,$satname);
	# print the current satellite position
	push @out,sprintf("Now   %2.2d:%2.2d %7.1f %7.1f %7.1f %7.1f %7.1f %7.1f", 
					  $hr,$min,$slat*$r2d,$slon*$r2d,$salt,
					  $az*$r2d,$el*$r2d,$distance);

	my $numsteps=0;
	$jtime=$jtime+$step/24/60;
	my $disc = 0;             # discontinuity flag
	while ( $numsteps < $numhours*60/$step ) # look $numhours  ahead for tracking table
	{
		my ($yr,$mon,$day,$hr,$min)=Sun::Calendar_date_and_time_from_JD($jtime);
		my ($slat,$slon,$salt,$az,$el,$distance)=Sun::get_satellite_pos($jtime,$lat*$d2r,$lon*$d2r,$alt,$satname);
		if ( $el*$r2d > -5 ) {
			if ($disc) {
				$disc = 0;
				push @out, $self->msg("satdisc");
			}
			push @out,sprintf("%2.2d/%2.2d %2.2d:%2.2d %7.1f %7.1f %7.1f %7.1f %7.1f %7.1f", 
							  $day,$mon,$hr,$min,$slat*$r2d,$slon*$r2d,$salt,
							  $az*$r2d,$el*$r2d,$distance);
		} else {
			$disc++;
		}
		$numsteps++;
		$jtime=$jtime+$step/60/24;
	}
} else {
	push @out, $self->msg("satnf", $satname) if $satname;
	push @out, $self->msg("sat3");
	push @out, $self->msg("sat4");
	my @l;
	my $i = 0;
	my $sat;
	foreach $sat (sort keys %Sun::keps) {
		if ($i >= 2) {
			push @out,join '  ', @l;
			@l = ();
			$i = 0;
		}
		my $epoch=$Sun::keps{$sat}->{epoch};
		my $jt_epoch=Sun::Julian_Date_of_Epoch($epoch);
		my $keps_age=int($jtime-$jt_epoch);
		push @l, sprintf("%20s: %4s",$sat,$keps_age);
		$i++;
	}
	push @out, join '  ', @l;
}

return (1,@out);











