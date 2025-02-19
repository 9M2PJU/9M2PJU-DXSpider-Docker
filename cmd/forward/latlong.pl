#
# forward/latlong <node> ...
#
# send out PC41s toward a node for every user that has a lat/long 
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) unless $self->priv >= 6;

my @dxchan;
my @out;
my $dxchan;

for ( map {uc $_ } split /\s+/, $line ) {
	if (($dxchan = DXChannel::get($_)) && $dxchan->is_node) {
		push @dxchan, $dxchan;
	} else {
		push @out, $self->msg('e10', $_);
	}
}
return (1, @out) if @out;

use DB_File;
	
my ($action, $count, $key, $data);
for ($action = R_FIRST, $count = 0; !$DXUser::dbm->seq($key, $data, $action); $action = R_NEXT) {
	if ($data =~ m{(?:lat|long) =>}) {
		my $u = DXUser::get_current($key);
		if ($u) {
			my $lat = $u->lat;
			my $long = $u->long;
			my $latlong = DXBearing::lltos($lat, $long) if $lat && $long;
			if ($latlong) {
				#push @out, $key;
				for (@dxchan) {
					my $s = DXProt::pc41($key, 3, $latlong);
					$s =~ s{H\d+\^~$}{H1^~};
					$dxchan->send($s);
				}
				++$count;
			}
		}
	}
}
return(1, @out, $self->msg('rec', $count));
