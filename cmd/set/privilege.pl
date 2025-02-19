#
# set the privilege of the user
#
# call as set/priv n <call> ...
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my $priv = shift @args;
my @out;
my $user;
my $ref;

if ($self->priv < 9 || $self->remotecmd || $self->inscript) {
	Log('DXCommand', $self->call . " attempted to set privilege $priv for @args");
	return (1, $self->msg('e5'));
}

if ($priv < 0 || $priv > 9) {
  return (1, $self->msg('e5')); 
}

foreach $call (@args) {
	$call = uc $call;
	unless ($self->remotecmd || $self->inscript) {
		if ($ref = DXChannel::get($call)) {
			$ref->priv($priv);
			$ref->user->priv($priv);
			$ref->user->put();
		}
		if (!$ref && ($user = DXUser::get($call))) {
			$user->priv($priv);
			$user->put();
		}
		if ($ref || $user) {
			push @out, $self->msg('priv', $call);
			Log('DXCommand', "Privilege set to $priv on $call by " . $self->call);
		} else {
			push @out, $self->msg('e3', "Set Privilege", $call);
		}
	} else {
		push @out, $self->msg('sorry');
		Log('DXCommand', $self->call . " attempted to set privilege $priv for $call remotely");
	}
}
return (1, @out);
