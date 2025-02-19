#
# set list of bad dx nodes
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->remotecmd;
# are we permitted?
return (1, $self->msg('e5')) if $self->priv < 6;
#$line = join(' ', map {s|[/-]\d+$||; $_} split(/\s+/, $line));
return $DXProt::badnode->set(8, $self->msg('e12'), $self, $line);

