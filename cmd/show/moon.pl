#!/usr/bin/perl
#
# show moonrise and moonset times for each callsign or prefix entered
#
# 1999/11/9 Steve Franke K9AN
# 2000/10/27 fixed bug involving degree to radian conversion.
# 2001/09/15 accept prefix/call and number of days from today (+ or -). 
#            e.g. sh/moon 2 w0 w9      shows rise/set 2 days hence for w0, w9
#                 sh/moon w0 w9 2      same thing
#            az and el are shown only when day offset is zero (i.e. today).

my ($self, $line) = @_;
my @f = split /\s+/, $line;

my @out;
my $f;
my $l;
my $n_offset;
my @list;
my ($rise, $set, $az, $dec, $loss, $ifrac);

while ($f = shift @f){
	if(!$n_offset){
		($n_offset) = $f =~ /^([-+]?\d+)$/;
		next if $n_offset;
	}
	push @list, $f;
}
$n_offset = 0 unless defined $n_offset;
$n_offset = 0 if $n_offset > 365;  # can request moon rise/set up to 1 year ago or from now... 
$n_offset = 0 if $n_offset < -365;

my ($lat, $lon);              # lats and longs in radians
my ($sec, $min, $hr, $day, $month, $yr) = (gmtime($main::systime+$n_offset*24*60*60))[0,1,2,3,4,5];

$month++;
$yr += 1900;

my @in;

if (@list) {
	foreach $l (@list) {
		my $user = DXUser::get_current(uc $l);
		if ($user && $user->lat && $user->long) {
			push @in, [$user->qth, $user->lat, -$user->long, uc $l ];
		} else {
			# prefixes --->
			my @ans = Prefix::extract($l);
			next if !@ans;
			my $pre = shift @ans;
			my $a;
			foreach $a (@ans) {
				$lat = $a->{lat};
				$lon = -$a->{long};
				push @in, [ $a->name, $lat, $lon, $pre ];
			}
		}
	}
} else {
	if ($self->user->lat && $self->user->long) {
		push @in, [$self->user->qth, $self->user->lat, -$self->user->long, $self->call ];
	} else {
		push @in, [$main::myqth, $main::mylatitude, -$main::mylongitude, $main::mycall ];
	}
}

if( !$n_offset ) {
	push @out, $self->msg('moon_with_azel');
} else {
	push @out, $self->msg('moon');
}

foreach $l (@in) {
	($rise, $set, $az, $dec, $loss, $ifrac)=Sun::rise_set($yr,$month,$day,$hr,$min,$l->[1],$l->[2],1);
	$l->[3] =~ s{(-\d+|/\w+)$}{};
	if( !$n_offset ) {	
	push @out,sprintf("%-6.6s %-30.30s %02d/%02d/%4d %s %s %6.1f %6.1f", $l->[3], $l->[0], $day, $month, $yr, $rise, $set, $az, $dec);
	} else {
	push @out,sprintf("%-6.6s %-30.30s %02d/%02d/%4d %s %s", $l->[3], $l->[0], $day, $month, $yr, $rise, $set);
	}
}
push @out,sprintf("Illuminated fraction of the Moon's disk is %4.2f",$ifrac);
return (1, @out);
