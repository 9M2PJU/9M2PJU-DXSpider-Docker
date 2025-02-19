#
# links : which are active
# a complete list of currently connected linked nodes
#
# Created by Iain Philipps G0RDI, based entirely on
# who.pl, which is Copyright (c) 1999 Dirk Koopman G1TLH
# and subsequently plagerized by K1XX.
#
# 16-Jun-2000
#
#

my $self = shift;
my $dxchan;
my @out;
my $nowt = time;

push @out, "                                                  Ave  Obs  Ping  Next      Filters";
push @out, "  Callsign Type Started                 Uptime    RTT Count Int.  Ping Iso? In  Out PC92? Address";

foreach $dxchan ( sort {$a->call cmp $b->call} DXChannel::get_all ) {
	next if $dxchan == $main::me;
	next unless $dxchan->is_node || $dxchan->is_rbn;
	my $call = $dxchan->call();
	my $t = cldatetime($dxchan->startt);
	my $sort;
	my $name = $dxchan->user->name || " ";
	my $obscount = $dxchan->nopings;
	my $pingint = $dxchan->pingint;
	my $lastt = $dxchan->lastping ? ($dxchan->pingint - ($nowt - $dxchan->lastping)) : $pingint;
	my $ping = sprintf("%7.2f", $dxchan->pingave || 0);
	my $iso = $dxchan->isolate ? 'Y' : ' ';
	my $uptime = difft($dxchan->startt, 1);
	my ($fin, $fout, $pc92) = (' ', ' ', ' ');
	if ($dxchan->do_pc9x) {
		$pc92 = 'Y';
	} else {
		my $f;
		if ($f = $dxchan->inroutefilter) {
			$fin = $dxchan->inroutefilter =~ /node_default/ ? 'D' : 'Y';
		}
		if ($f = $dxchan->routefilter) {
			$fout = $dxchan->routefilter =~ /node_default/ ? 'D' : 'Y';
		}
	}
	unless ($pingint && $ping) {
		$lastt = 0;
		$ping = '       ';
		$obscount = ' ';
	}

	$sort = "DXSP" if $dxchan->is_spider;
	$sort = "CLX " if $dxchan->is_clx;
	$sort = "DXNT" if $dxchan->is_dxnet;
	$sort = "AR-C" if $dxchan->is_arcluster;
	$sort = "AK1A" if $dxchan->is_ak1a;
	$sort = "RBN " if $dxchan->is_rbn;
	my $ipaddr;

	my $addr = $dxchan->hostname;
	if ($addr) {
	    $ipaddr = $addr if is_ipaddr($addr);
		$ipaddr = 'local' if $addr =~ /^127\./ || $addr =~ /^::[0-9a-f]+$/;
	}
	$ipaddr = 'ax25' if $dxchan->conn->ax25;

	push @out, sprintf "%10s $sort $t%13s$ping   $obscount  %5d %5d  $iso    $fin   $fout   $pc92    $ipaddr", $call, $uptime ,$pingint, $lastt;
}

return (1, @out)




