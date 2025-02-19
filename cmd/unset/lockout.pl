#
# unlock a locked out user 
#
# Copyright (c) 1998 Iain Phillips G0RDI
#
#
#
my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
# my $priv = shift @args;
my @out;
my $user;
my $ref;

if ($self->priv < 9) {
	Log('DXCommand', $self->call . " attempted to un-lockout @args");
	return (1, $self->msg('e5'));
}

foreach $call (@args) {
	$call = uc $call;
	unless ($self->remotecmd || $self->inscript) {
		if ($ref = DXUser::get_current($call)) {
			$ref->lockout(0);
			$ref->put();
			push @out, $self->msg("lockoutun", $call);
			Log('DXCommand', $self->call . " un-locked out $call");
		} else {
			push @out, $self->msg('e3', 'unset/lockout', $call);
		}
	} else {
		Log('DXCommand', $self->call . " attempted to un-lockout $call remotely");
		push @out, $self->msg('sorry');
	}
}
return (1, @out);
