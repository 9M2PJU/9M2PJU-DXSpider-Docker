#!/usr/bin/perl
#
# pretend that you are another user, execute a command
# as that user, then send the output back to them.
#
# This is for educating users....
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#
my ($self, $line) = @_;

my ($call, $newline) = split /\s+/, $line, 2;
$call = uc $call;
my $dxchan = DXChannel::get($call);
my $mycall = $self->call;

return (1, $self->msg('e7', $call)) unless $dxchan;
return (1, $self->msg('e31', $call)) unless $dxchan->is_user;
if ($self->remotecmd || $self->inscript) {
	Log('DXCommand', "$mycall is trying to 'demo' to $call remotely");
	return (1, $self->msg('e5'));
}
if ($self->priv < 9) {
	Log('DXCommand', "$mycall is trying to 'demo' to $call locally");
	return (1, $self->msg('e5'));
}
Log('DXCommand', "demo '$newline' to $call by $mycall");
my @in = $dxchan->run_cmd($newline);

$dxchan->send($newline, @in);

return (1, map { "->$call: $_" } @in);
