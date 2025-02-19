#
# set the page length for this invocation of the client
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#
my $self = shift;
my $l = shift;
$l = 10 if $l < 10 && $l > 0;
$self->pagelth($l);
$self->user->pagelth($l);
return (1, $self->msg('pagelth', $l));
