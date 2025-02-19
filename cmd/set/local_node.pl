#
# add these nodes to the 'local_node' group
#
# Copyright (c) 2006 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, uc $line;
my @out;

return (1, $self->msg('e5')) unless $self->priv >= 5;

foreach my $call (@args) {
	my $user = DXUser::get_current($call);
	push(@out, $self->msg('e3', 'set/localnode', $call)), next unless $user; 
	push(@out, $self->msg('e13', $call)), next unless $user->is_node; 
	my $group = $user->group || [];
	push @$group, 'local_node' unless grep $_ eq 'local_node', @$group;
	my $dxchan = DXChannel::get($call);
	$dxchan->group($group) if $dxchan;
	push @out, $self->msg('lgset', $call);
	$user->put;
}

return (1, @out);
