#
# Add a believable node - used to filter nodes as being believable
#
# Copyright (c) 2004 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, uc $line;
my $call;
my $node = shift @args;
my @out;
my @nodes;

return (1, $self->msg('e5')) if $self->priv < 6;
return (1, $self->msg('e22', $node)) unless is_callsign($node);
my $user = DXUser::get_current($node);
return (1, $self->msg('e13', $node)) unless $user->is_node;

foreach $call (@args) {
	return (1, $self->msg('e22', $node)) unless is_callsign($call);

	my $u = DXUser::get_current($call);
	push @nodes, $call;
}

foreach $call (@nodes) {
	$user->unset_believe($call);
	push @out, $self->msg('believeu', $call, $node);
}
$user->put if @nodes;
		
return (1, @out);
