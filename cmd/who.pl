#
# who : is online
# a complete list of stations connected
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#


my $self = shift;
my $dxchan;
my @out;

push @out, "  Callsign Type      Started           Name     Ave RTT Link";

foreach $dxchan ( sort {$a->call cmp $b->call} DXChannel::get_all ) {
    my $call = $dxchan->call();
	my $t = cldatetime($dxchan->startt);
	my $type = $dxchan->is_node ? "NODE" : "USER";
	my $sort = "    ";
	if ($dxchan->is_node) {
		$sort = "DXSP" if $dxchan->is_spider;
		$sort = "CLX " if $dxchan->is_clx;
		$sort = "DXNT" if $dxchan->is_dxnet;
		$sort = "AR-C" if $dxchan->is_arcluster;
		$sort = "AK1A" if $dxchan->is_ak1a;
	} else {
		$sort = "LOCL" if $dxchan->conn->isa('IntMsg');
		$sort = "WEB " if $dxchan->is_web;
		$sort = "EXT " if $dxchan->conn->isa('ExtMsg');
		$type = "RBN " if $dxchan->is_rbn;              # Yes, this is NOT a typo
	}
	my $name = $dxchan->user->name || " ";
	my $ping = $dxchan->is_node && $dxchan != $main::me ? sprintf("%5.2f", $dxchan->pingave) : "     ";
	my $conn = $dxchan->conn;
	my $ip = '';
	if ($conn) {
		$ip = $dxchan->hostname;
		$ip = "AGW Port ($conn->{agwport})" if exists $conn->{agwport};
	}
	push @out, sprintf "%10s $type $sort $t %-10.10s $ping $ip", $call, $name;
}

return (1, @out)
