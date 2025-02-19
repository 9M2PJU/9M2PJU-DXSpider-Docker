#
# set a user's password
#
# Copyright (c) 1998 Iain Phillips G0RDI
# 21-Dec-1998
#
# Syntax:	set/pass <callsign> <password> 
#

my ($self, $line) = @_;
my @args = split /\s+/, $line, 2;
my $call = shift @args;
my @out;
my $user;
my $ref;

if ($self->remotecmd || $self->inscript) {
	$call ||= $self->call;
	Log('DXCommand', $self->call . " attempted to change password for $call remotely");
	return (1, $self->msg('e5'));
}

if ($call) {
	if ($self->priv < 9) {
		Log('DXCommand', $self->call . " attempted to change password for $call");
		return (1, $self->msg('e5'));
	}
	return (1, $self->msg('e29')) unless @args;
	if ($ref = DXUser::get_current($call)) {
		$ref->passwd($args[0]);
		$ref->put();
		push @out, $self->msg("password", $call);
		Log('DXCommand', $self->call . " changed password for $call");
	} else {
		push @out, $self->msg('e3', 'User record for', $call);
	}
} else {
	if ($self->conn->{csort} eq 'telnet' && $self->user->passwd) {
		$self->conn->{decho} = $self->conn->{echo};
		$self->conn->{echo} = 0;
		push @out, $self->msg('pw0');
		$self->state('passwd');
	} else {
		push @out, $self->msg('e5');
	}
}

return (1, @out);
