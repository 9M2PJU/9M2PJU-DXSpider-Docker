#
# reverse init a cluster connection
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
			my $parent = Route::Node::get($call);
			$dxchan->state('init');
			$dxchan->send_local_config;
			$dxchan->send(DXProt::pc20());
			push @out, $self->msg('init1', $call);
		} 
	} else {
		push @out, $self->msg('e10', $call);
	}
}

return (1, @out);

