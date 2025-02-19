#
# set the logininfo option for users
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#
#
my $self = shift;
$self->user->wantlogininfo(1);
$self->logininfo(1);
return (1, $self->msg('ok'));
