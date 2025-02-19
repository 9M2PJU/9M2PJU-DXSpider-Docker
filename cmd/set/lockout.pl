#
# lock a user out
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
	Log('DXCommand', $self->call . " attempted to lockout @args");
	return (1, $self->msg('e5'));
}

foreach $call (@args) {
	$call = uc $call;
	unless ($self->remotecmd || $self->inscript) {
		if ($ref = DXUser::get_current($call)) {
			$ref->lockout(1);
			$ref->put();
			push @out, $self->msg("lockout", $call);
		} else {
			$ref = DXUser->new($call);
			$ref->lockout(1);
			$ref->put();
			push @out, $self->msg("lockoutc", $call);
		}
		Log('DXCommand', $self->call . " locked out $call");
	} else {
		Log('DXCommand', $self->call . " attempted to lockout $call remotely");
		push @out, $self->msg('sorry');
	}
}
return (1, @out);
