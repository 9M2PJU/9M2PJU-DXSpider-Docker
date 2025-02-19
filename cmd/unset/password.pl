#
# unset a user's password
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
# Syntax:	unset/pass <callsign> ... 
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my @out;
my $user;
my $ref;

if ($self->remotecmd || $self->inscript) {
	Log('DXCommand', $self->call . " attempted to unset password for @args remotely");
	return (1, $self->msg('e5'));
}

if ($self->priv < 9) {
	Log('DXCommand', $self->call . " attempted to unset password for @args");
	return (1, $self->msg('e5'));
}

for (@args) {
	my $call = uc $_;
	if ($ref = DXUser::get_current($call)) {
		$ref->unset_passwd;
		$ref->put();
		push @out, $self->msg("passwordu", $call);
		Log('DXCommand', $self->call . " unset password for $call");
	} else {
		push @out, $self->msg('e3', 'User record for', $call);
	}
}

return (1, @out);
