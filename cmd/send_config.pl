#
# send out PC92 config records manually
#

my $self = shift;
return (1, $self->msg('e5')) unless $self->priv > 5;

$main::me->broadcast_pc92_update($main::mycall);

return (1, $self->msg('ok'));
