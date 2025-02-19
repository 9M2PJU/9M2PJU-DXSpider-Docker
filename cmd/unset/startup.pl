#
# remove a startup script
#
# Copyright (c) 2005 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->remotecmd || $self->inscript;
return (1, $self->msg('e5')) if $line && $self->priv < 5;

my @out;

Script::erase($line || $self->call);
push @out, $self->msg('done');
return (1, @out);
