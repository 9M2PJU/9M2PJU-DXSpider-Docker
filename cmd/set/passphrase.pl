#
# set a user's passphrase
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#
# Syntax:	set/passphrase <callsign> <password> 
#

my ($self, $line) = @_;
my @args = split /\s+/, $line, 2;
my $call = shift @args;
my @out;
my $user;
my $ref;

if ($self->remotecmd || $self->inscript) {
	$call ||= $self->call;
	Log('DXCommand', $self->call . " attempted to change passphrase for $call remotely");
	return (1, $self->msg('e5'));
}

if ($call) {
	if ($self->priv < 9) {
		Log('DXCommand', $self->call . " attempted to change passphrase for $call");
		return (1, $self->msg('e5'));
	}
	return (1, $self->msg('e29')) unless @args;
	if ($ref = DXUser::get_current($call)) {
		$ref->passphrase($args[0]);
		$ref->put();
		push @out, $self->msg("passphrase", $call);
		Log('DXCommand', $self->call . " changed passphrase for $call");
	} else {
		push @out, $self->msg('e3', 'User record for', $call);
	}
}

return (1, @out);
