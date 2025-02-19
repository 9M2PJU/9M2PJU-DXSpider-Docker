#
# Query the DB0SDX QSL server for a callsign
#
# Copyright (c) 2003 Dirk Koopman G1TLH
# Modified Dec 9, 2004 for new website and xml schema by David Spoelstra N9KT
# and tidied up by me (Dirk)
#
#
#

sub on_disc
{
	my $conn = shift;
	my $dxchan = shift;
	my @out;
	
	$conn->{sdxin} .= $conn->{msg};	# because there will be stuff left in the rx buffer because it isn't \n terminated
	dbg("db0sdx in: $conn->{sdxin}") if isdbg('db0sdx');

	my ($info) = $conn->{sdxin} =~ m|<qslinfoResult>([^<]*)</qslinfoResult>|;
	dbg("info: $info");
	my $prefix = $conn->{prefix} || '';
	
	my @in = split /[\r\n]/, $info if $info;
	if (@in && $in[0]) {
		dbg("in qsl");
		push @out, map {"$prefix$_"} @in;
	} else {
		dbg("in fault");
		($info) = $conn->{sdxin} =~ m|<faultstring>([^<]*)</faultstring>|;
		push @out, "$prefix$info" if $info;
		push @out, $dxchan->msg('e3', 'DB0SDX', $conn->{sdxline}) unless @out;		
	}
	$dxchan->send(@out);
}

sub process
{
	my $conn = shift;
	my $msg = shift;

	$conn->{sdxin} .= "$msg\n";
	
	dbg("db0sdx in: $conn->{sdxin}") if isdbg('db0sdx');
}

sub handle
{
	my ($self, $line) = @_;
	my $call = $self->call;
	my @out;

	$line = uc $line;
	return (1, $self->msg('e24')) unless $Internet::allow;
	return (1, "SHOW/DB0SDX <callsign>, e.g. SH/DB0SDX ea7wa") unless $line && is_callsign($line);
	my $target = $Internet::db0sdx_url || 'www.qslinfo.de';
	my $path = $Internet::db0sdx_path || '/qslinfo';
	my $suffix = $Internet::db0sdx_suffix || '.asmx';
	my $port = 80;

	dbg("db0sdx: contacting $target:$port") if isdbg('db0sdx');

	my $s = qq(<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <qslinfo xmlns="http://$target">
      <callsign>$line</callsign>
      <ClientInformation>DXSpider V$main::version B$main::build ($call\@$main::mycall)</ClientInformation>
    </qslinfo>
  </soap:Body>
</soap:Envelope>);
	my $lth = length($s)+1;
	
	Log('call', "$call: show/db0sdx $line");
	my $conn = AsyncMsg->post($self, $target, $port, "$path$suffix", prefix => 'sdx> ', filter => \&process,
							 'Content-Type' => 'text/xml; charset=utf-8',
							 'Content-Length' => $lth,
							  Connection => 'Close',
							  SOAPAction => qq{"http://$target$path"},
							  data => $s,
							  on_disc => \&on_disc);
	
	if ($conn) {
		$conn->{sdxcall} = $line;
		push @out, $self->msg('m21', "show/db0sdx");
	} else {
		push @out, $self->msg('e18', 'DB0SDX Database server');
	}

	return (1, @out);
}
