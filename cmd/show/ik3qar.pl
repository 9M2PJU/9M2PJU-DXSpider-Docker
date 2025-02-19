#
# Query the IK3QAR Database server for a callsign
#
# from an idea by Paolo,IK3QAR and Leo,IZ5FSA
#
# $Id$
#

sub handle
{
	my ($self, $line) = @_;
	my $op;
	my $call = $self->call;
	my @out;

	return (1, $self->msg('e24')) unless $Internet::allow;
	return (1, "SHOW/IK3QAR <callsign>\n  e.g. SH/IK3QAR II5I, SH/IK3QAR V51AS\n") unless $line;

	my $target = $Internet::ik3qar_url;
	my $port = 80;
	my $url = "http://".$target;

	$line = uc $line;
	dbg("IK3QAR: call = $line") if isdbg('ik3qar');
	$op="call=$line\&node=$main::mycall\&passwd=$Internet::ik3qar_pw\&user=$call";	
	my $path = "/manager/dxc/dxcluster.php?$op";
	dbg("IK3QAR: url=$path") if isdbg('ik3qar');
	Log('call', "$call: SH/IK3QAR $line");
	
	my $r = AsyncMsg->get($self, $target, $port, $path, prefix=>'qar> ',
						  'User-Agent' => "DxSpider;$main::version;$main::build;$^O;$main::mycall;$call");
	if ($r) {
		push @out, $self->msg('m21', "show/ik3qar");
	} else {
		push @out, $self->msg('e18', 'Open(IK3QAR.it)');
	}
 
	return (1, @out);
}
