#
# set the page width for this invocation of the client
#
# Copyright (c) 2021 - Dirk Koopman G1TLH
#
#
#
my $self = shift;
my $l = shift;
$l = 80 if $l < 80;
$self->width($l);
$self->user->width($l);
return (1, $self->msg('pagewidth', $l));
