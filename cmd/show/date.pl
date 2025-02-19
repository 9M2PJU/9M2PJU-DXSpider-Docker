#
# Return system date & time to pacify G4PDQ
#
# Copyright (c) 1999 Dirk Koopman G1TLH
# Copyright (c) 2000 Iain Philipps G0RDI
#
# Shamelessly cribbed from time.pl:-
#
#
#


my ($self, $line) = @_;
my @list = split /\s+/, $line;

my $l;
my @out;
my $t = $main::systime;

push @out, $self->msg("time3", cldate($t, 1), ztime($t));

if (@list) {
	foreach $l (@list) {
		# prefixes --->
		my @ans = Prefix::extract($l);
		next if !@ans;
		my $pre = shift @ans;
		my $a;
		foreach $a (@ans) {
			my $s = sprintf "%-9s %-20s", $pre, $a->name();

			# UTC offset is in hours.minutes (too late to change it now) AND
            # the wrong way round!
			my $off = $a->utcoff();
			my $frac = $off - int $off;
			$off = (int $off) + (($frac*100)/60);
			my ($sec,$min,$hour) = gmtime($t - 3600*$off);
			my $buf = sprintf "%02d%02d", $hour, $min;
			push @out, $self->msg("time2", $s, $buf, sprintf("%+.1f", -$off));
		}
	}
} 

return (1, @out);
