#
# set echoing
#
# Copyright (c) 2000 - Dirk Koopman G1TLH
#
#
#
my $self = shift;
$self->send_now("E", "0");
$self->user->wantecho(0);
return (1, $self->msg('echooff'));
