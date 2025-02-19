#
# disconnect a local user
#
my ($self, $line) = @_;
my @calls = split /\s+/, $line;
my $call;
my @out;

if ($self->priv < 5) {
	return (1, $self->msg('e5'));
}

if ($calls[0] =~ /^user/i ) {
	@calls = grep {$_ ne $self->call} DXChannel::get_all_user_calls();
} elsif ($calls[0] =~ /^node/i) {
	@calls = grep {$_ ne $main::mycall} DXChannel::get_all_node_calls();
} elsif (lc $calls[0] eq 'all') {
	@calls = grep {$_ ne $main::mycall && $_ ne $self->call} DXChannel::get_all_node_calls(), DXChannel::get_all_user_calls();
}
foreach $call (@calls) {
	$call = uc $call;
	next if $call eq $main::mycall;
	my $dxchan = DXChannel::get($call);
	if ($dxchan) {
		if ($dxchan->is_node) {
#			$dxchan->send_pc39($self->msg('disc1', $self->call));
		} else {
			return (1, $self->msg('e5')) if $self->priv < 8;
			$dxchan->send_now('D', $self->msg('disc1', $self->call));
		} 
		$dxchan->disconnect;
		push @out, $self->msg('disc2', $call);
	} elsif (my $conn = Msg->conns($call)) {
		$conn->disconnect;
		push @out, $self->msg('disc3', $call);
#	} elsif (my $ref = DXCluster->get_exact($call)) {
#		my $dxchancall = $ref->dxchancall;
#		if ($dxchancall eq $main::mycall || !DXChannel::get($dxchancall)) {
#			$ref->del;
#			push @out, $self->msg('disc4', $call);
#		}
	} else {
		push @out, $self->msg('e10', $call);
	}
}

return (1, @out);
