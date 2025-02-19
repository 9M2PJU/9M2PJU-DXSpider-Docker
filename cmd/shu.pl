#
# Command to force people to type at least 'shut' to shutdown
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#
#
#

my $self = shift;

if ($self->priv >= 5) {
	return (1, $self->msg('shu'))
} else {
	return (1, $self->msg('e1'));
}
