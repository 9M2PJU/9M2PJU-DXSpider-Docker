#
# remove these nodes from the 'local_node' group
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
	my @new = grep {$_ ne 'local_node'} @$group;
	$user->group(\@new);
	my $dxchan = DXChannel::get($call);
	$dxchan->group(\@new) if $dxchan;
	push @out, $self->msg('lgunset', $call);
	$user->put;
}

return (1, @out);
