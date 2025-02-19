#
# set beeps
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#
my $self = shift;
$self->beep(1);
$self->user->wantbeep(1);
return (1, $self->msg('beepon'));
