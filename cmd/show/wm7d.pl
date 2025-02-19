#
# Query the WM7D Database server for a callsign
#
# Was Largely based on "sh/qrz"
#
# Original Copyright (c) 2002 Charlie Carroll K1XX
#
# Async version (c) Dirk Koopman G1TLH
#

sub waitfor
{
	my $conn = shift;
	my $msg = shift;
	$msg =~ s/\cM//g;

	my $buf = $conn->{msg};
	$buf =~ s/\r/\\r/g;
	$buf =~ s/\n/\\n/g;
	dbg "state $conn->{state} '$msg' '$buf'";
	
	if ($conn->{state} eq 'waitfor') {
		if ($msg =~ /utc$/ ) { 
			$conn->send_later("$conn->{target_call}\n");
			$conn->{state} = 'working';
		}
	} elsif ($conn->{state} eq 'working') {
		if ($conn->{msg} =~ /^\rquery->\s*$/) {
			$conn->send_later("QUIT\n");
			$conn->{state} = 'ending';
		}
		return if $msg =~ /^query->/;
		$conn->handle_raw($msg);
	} else {
		return if $msg =~ /^query->/ || $msg =~ /bye/;
		$conn->handle_raw($msg);
	}
}

# wm7d accepts only single callsign
sub handle
{

	my ($self, $line) = @_;
	my $call = $self->call;
	my @out;

#	$DB::single = 1;
	

	# send 'e24' if allow in Internet.pm is not set to 1
	return (1, $self->msg('e24')) unless $Internet::allow;
	return (1, "SHOW/WM7D <callsign>, e.g. SH/WM7D k1xx") unless $line;
	my $target = $Internet::wm7d_url || 'www.wm7d.net';
	my $port = 5000;
	my $cmdprompt = '/query->.*$/';

	Log('call', "$call: show/wm7d \U$line");

	my $conn = AsyncMsg->raw($self, $target, $port,
							 handler => \&waitfor, prefix=>'wm7d> ');
	if ($conn) {
		$conn->{state} = 'waitfor';
		$conn->{target_call} = $line;
		
		push @out, $self->msg('m21', "show/wm7d");
	} else {
		push @out, $self->msg('e18', 'WM7D.net');
	}

	return (1, @out);
}

