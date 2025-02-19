#
# set the latitude and longtitude field
#
# Copyright (c) 1998 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

# remove leading and trailing spaces
$line =~ s/^\s+//;
$line =~ s/\s+$//;

return (1, $self->msg('loce1')) if !$line;
return (1, $self->msg('loce3', uc $line)) if is_qra($line);
return (1, $self->msg('loce2', $line)) unless is_latlong($line);

$user = DXUser::get_current($call);
if ($user) {
	$line = uc $line;
	my ($lat, $long) = DXBearing::stoll($line);
	my $oldlat = $user->lat || 0;
	my $oldlong = $user->long || 0;
	if ($oldlat != $lat || $oldlong != $long) {
		$user->lat($lat);
		$user->long($long);
		my $l = DXBearing::lltos($lat, $long);
		my $s = DXProt::pc41($call, 3, $l);
		DXProt::eph_dup($s);
		DXChannel::broadcast_all_nodes($s, $main::me) ;
	}
	my $qra = DXBearing::lltoqra($lat, $long);
	my $oldqra = $user->qra || "";
	if ($oldqra ne $qra) {
		$user->qra($qra);
		my $s = DXProt::pc41($call, 5, $qra);
		DXProt::eph_dup($s);
		DXChannel::broadcast_all_nodes($s, $main::me);
	}
	
	$user->put();
	return (1, $self->msg('loc', $line));
} else {
	return (1, $self->msg('namee2', $call));
}
