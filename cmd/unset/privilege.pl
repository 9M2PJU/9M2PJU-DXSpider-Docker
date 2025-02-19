#
# unset any privileges that the user might have for THIS SESSION only
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
$self->priv(0);
return (1, $self->msg('done'));

