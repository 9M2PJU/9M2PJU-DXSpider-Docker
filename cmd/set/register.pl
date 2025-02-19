#
# register a user
#
# Copyright (c) 2001 Dirk Koopman G1TLH
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
	Log('DXCommand', $self->call . " attempted to register @args");
	return (1, $self->msg('e5'));
}
#return (1, $self->msg('reginac')) unless $main::reqreg;

foreach $call (@args) {
	$call = uc $call;
	unless ($self->remotecmd || $self->inscript) {
		if ($ref = DXUser::get_current($call)) {
			$ref->registered(1);
			$ref->put();
			push @out, $self->msg("reg", $call);
		} else {
			$ref = DXUser->new($call);
			$ref->registered(1);
			$ref->put();
			push @out, $self->msg("regc", $call);
		}
		my $dxchan = DXChannel::get($call);
		$dxchan->registered(1) if $dxchan;
		Log('DXCommand', $self->call . " registered $call");
	} else {
		Log('DXCommand', $self->call . " attempted to register $call remotely");
		push @out, $self->msg('sorry');
	}
}
return (1, @out);
