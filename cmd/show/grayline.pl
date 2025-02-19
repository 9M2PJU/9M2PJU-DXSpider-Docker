#!/usr/bin/perl
#
# show dawn, sunrise, sunset, and dusk times for each callsign or prefix entered
#
# 
my ($self, $line) = @_;
my @f = split /\s+/, $line;

my @out;
my $f;
my $l;
my $n_offset;
my @list;

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

push @out, $self->msg('grayline1');
push @out, $self->msg('grayline2');

foreach $l (@in) {
        my ($dawn, $rise, $set, $dusk, $az, $dec )=Sun::rise_set($yr,$month,$day,$hr,$min,$l->[1],$l->[2],0);
        $l->[3] =~ s{(-\d+|/\w+)$}{};
        push @out,sprintf("%-6.6s %-30.30s %02d/%02d/%4d %s %s %s %s", $l->[3], $l->[0], $day, $month, $yr, $dawn, $rise, $set, $dusk);
}


return (1, @out);
