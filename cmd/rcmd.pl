#
# rcmd command
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my $self = shift;
my $line = shift; 
my ($call) = $line =~ /^\s*(\S+)/;
return (1, $self->msg('e5')) if $self->remotecmd;

# are we permitted?
return (1, $self->msg('e5')) if $self->priv < 6;

# is there a call?
return (1, $self->msg('e6')) unless $call;

# remove the callsign from the line
$line =~ s/^\s*$call\s+//;

# can we see it? Is it a node?
$call = uc $call;
my $noderef = Route::Node::get($call);
return (1, $self->msg('e7', $call)) unless $noderef;

# rcmd it
DXProt::addrcmd($self, $call, $line);

return (1, $self->msg('rcmdo', $line, $call));
