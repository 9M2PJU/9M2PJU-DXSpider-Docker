#
# show the usdb info for each callsign or prefix entered
#
#
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#

my ($self, $line) = @_;
my @list = split /\s+/, $line;	# generate a list of callsigns

my $l;
my @out;

return (1, $self->msg('db3', 'FCC USDB')) unless $USDB::present;
		
#print "line: $line\n";
foreach $l (@list) {
    $l = uc $l;
	my ($city, $state) = USDB::get($l);
	if ($state) {
		push @out, sprintf "%-7s -> %s, %s", $l, 
			join (' ', map {ucfirst} split(/\s+/, lc $city)), $state;
	} else {
		push @out, sprintf "%-7s -> Not Found", $l;
	}
}

return (1, @out);
