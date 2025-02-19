#
# unset the gtk flag
#
# Copyright (c) 2006 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @out;
$self->gtk(0);
$self->enhanced(0);
push @out, $self->msg('gtku', $self->call);
return (1, @out);
