#
# set the cluster qra locator field
#
# Copyright (c) 1998 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 9;
my @out = run_cmd($self, "set/qra $line");
return (1, run_cmd($main::me, "set/qra $line"));
