#
# go INSTANTLY into debug mode (if you are in the debugger!)
#
# remember perl -d cluster.pl to use this
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;

$DB::single = 1;

