#
# clear out and replace dupefile with an empty one
#
# Copyright (c) 2007 Dirk Koopman, G1TLH
#
#

my ($self, $line) = @_;

# are we permitted (we could allow fairly privileged people to do this)?
return (1, $self->msg('e5')) if $self->priv < 6;

DXDupe::finish();
DXDupe::init();

return (1, $self->msg('done'));



