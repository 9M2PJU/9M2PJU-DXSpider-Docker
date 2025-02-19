#
# ping command
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my $self = shift;
my $line = uc shift;   # only one callsign allowed 
my ($call) = $line =~ /^\s*(\S+)/;

# are we permitted?
return (1, $self->msg('e5')) if $self->priv < 1;

# is there a call?
return (1, $self->msg('e6')) if !$call;

# is it me?
return (1, $self->msg('pinge1')) if $call eq $main::mycall;

# can we see it? Is it a node?
my $noderef = Route::Node::get($call);

return (1, $self->msg('e7', $call)) unless $noderef;

# ping it
DXXml::Ping::add($self, $call);

return (1, $self->msg('pingo', $call));


