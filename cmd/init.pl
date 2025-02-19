#
# init a cluster connection
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my @calls = split /\s+/, $line;
my $call;
my @out;

return (1, $self->msg('e5')) if $self->priv < 5;

foreach $call (@calls) {
	$call = uc $call;
	next if $call eq $main::mycall;
	my $dxchan = DXChannel::get($call);
	if ($dxchan) {
		if ($dxchan->is_node) {
			# first clear out any nodes on this dxchannel
			my $parent = Route::Node::get($call);
			my @rout = $parent->del_nodes;
			$dxchan->route_pc21(undef, $self, @rout) if @rout;
			$dxchan->send(DXProt::pc18());
			$dxchan->state('init');
			push @out, $self->msg('init1', $call);
		} 
	} else {
		push @out, $self->msg('e10', $call);
	}
}

return (1, @out);

