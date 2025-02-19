#
# send debug information to this connection
#
# Copyright (c) 2001 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 8;
$self->senddbg(1);
return (1, $self->msg('done'));
