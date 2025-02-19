#
# send a manual PC protocol (or other) message to the callsign
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#
my $self = shift;
my $line = shift;
my @f = split /\s+/, $line;

return (1, $self->msg('e5')) if $self->priv < 8 || $self->remotecmd || $self->inscript;

my $call = uc shift @f;
my $dxchan = DXChannel::get($call);
return (1, $self->msg('e10', $call)) if !$dxchan;
return (1, $self->msg('e8')) if @f <= 0;

$line =~ s/$call\s+//i;   # remove callsign and space
$dxchan->send($line);

return (1);
