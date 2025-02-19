#
# Query the 425 Database server for a callsign
#
# from an idea by Leo,IZ5FSA and 425DxNews Group
#
#
#

sub handle
{
	my ($self, $line) = @_;
	my @list = map {uc} split /\s+/, $line;	# generate a list of callsigns
	my $op;
	my $call = $self->call;
	my @out;

	return (1, $self->msg('e24')) unless $Internet::allow;
	return (1, "SHOW/425 <callsign>\nSHOW/425 CAL\nSHOW/425 BULL <bulletin number>\n e.g. SH/425 IQ5BL, SH/425 CAL, SH/425 BUL 779\n") unless @list;

	my $target = $Internet::dx425_url || 'www.425dxn.org';
	my $port = 80;

	dbg('sh/425: args=' . join('|', @list)) if isdbg('425');
	if ($list[0] eq "CAL") {
		$op="op=cal";
	} elsif ($list[0] eq "BULL") {
		$op="op=bull&query=$list[1]";
	} else {
		$op="op=search&query=$list[0]";
	}
	
	my $path = "/spider.php?$op";

	dbg("sh/425: target='$target' path='$path'") if isdbg('425'); 
	
	Log('call', "$call: show/425 \U$op");
	my $conn = AsyncMsg->get($self, $target, $port, $path, prefix=>'425> ', 'User-Agent' => qq{DxSpider;$main::version;$main::build;$^O;$main::mycall;$call;$list[0]});
	
	if ($conn) {
		push @out, $self->msg('m21', "show/425");
	} else {
        push @out, $self->msg('e18', 'Open(ARI.org)');
	}

	return (1, @out);
}

