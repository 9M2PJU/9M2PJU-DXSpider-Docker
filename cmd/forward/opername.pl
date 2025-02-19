#
# Cause node to send PC41 info frames
#
# Copyright (c) 1998 - Iain Philipps G0RDI
#
# Mods by Dirk Koopman G1TLH 12Dec98
#

my ($self, $line) = @_;
my @f = split /\s+/, uc $line;
my @out;

if ($self->priv < 1) {
	if (@f == 0) {
		push @f, $self->call;
	} else {
		return (1, $self->msg('e5'));
	}
} elsif (@f == 0) {
	return (1, $self->msg('e6'));
}

my $call;
foreach $call (@f) {
	my $ref = DXUser::get_current($call);
	if ($ref) {
		my $name = $ref->name;  
		my $qth = $ref->qth;
		my $lat = $ref->lat;
		my $long = $ref->long;
		my $node = $ref->homenode;
		my $qra = $ref->qra;
		my $latlong = DXBearing::lltos($lat, $long) if $lat && $long;
		if ($name) {
			my $l = DXProt::pc41($main::me, $call, 1, $name);
			DXProt::eph_dup($l);
			DXChannel::broadcast_all_nodes($l, $main::me) ;
		}
		if ($qth) {
			my $l = DXProt::pc41($call, 2, $qth);
			DXProt::eph_dup($l);
			DXChannel::broadcast_all_nodes($l, $main::me) ;
		}
		if ($latlong) {
			my $l = DXProt::pc41($call, 3, $latlong);
			DXProt::eph_dup($l);
			DXChannel::broadcast_all_nodes($l, $main::me) ;
		}
		if ($node) {
			my $l = DXProt::pc41($call, 4, $node);
			DXProt::eph_dup($l);
			DXChannel::broadcast_all_nodes($l, $main::me) ;
		}
		if ($qra) {
			my $l = DXProt::pc41($call, 5, $qra);
			DXProt::eph_dup($l);
			DXChannel::broadcast_all_nodes($l, $main::me) ;
		}
	}
}

return (1, @out);
