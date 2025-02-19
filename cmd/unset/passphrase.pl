#
# unset a user's passphrase
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#
# Syntax:	unset/passphrase <callsign> ... 
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my @out;
my $user;
my $ref;

if ($self->remotecmd || $self->inscript) {
	Log('DXCommand', $self->call . " attempted to unset passphrase for @args remotely");
	return (1, $self->msg('e5'));
}

if ($self->priv < 9) {
	Log('DXCommand', $self->call . " attempted to unset passphrase for @args");
	return (1, $self->msg('e5'));
}

for (@args) {
	my $call = uc $_;
	if ($ref = DXUser::get_current($call)) {
		$ref->unset_passphrase;
		$ref->put();
		push @out, $self->msg("passphraseu", $call);
		Log('DXCommand', $self->call . " unset passphrase for $call");
	} else {
		push @out, $self->msg('e3', 'User record for', $call);
	}
}

return (1, @out);
