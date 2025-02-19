#
# do anything
#
# Rape me!
#
# Copyright (c) 2000 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 9 || $self->remotecmd || $self->inscript;
Log('DXCommand', $self->call . " do $line" );
eval "$line";
return (1, $@ ? $@ : "Ok, done $line" );
