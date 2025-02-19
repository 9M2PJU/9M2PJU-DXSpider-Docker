#
# set the gtk flag
#
# Copyright (c) 2006 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @out;
$self->gtk(1);
$self->enhanced(1);
push @out, $self->msg('gtks', $self->call);
return (1, @out);
