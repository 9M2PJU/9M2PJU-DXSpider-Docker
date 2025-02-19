#
# unregister a user
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
	Log('DXCommand', $self->call . " attempted to unregister @args");
	return (1, $self->msg('e5'));
}
#return (1, $self->msg('reginac')) unless $main::reqreg;

foreach $call (@args) {
	$call = uc $call;
	unless ($self->remotecmd || $self->inscript) {
		if ($ref = DXUser::get_current($call)) {
			$ref->registered(0);
			$ref->put();
			my $dxchan = DXChannel::get($call);
			$dxchan->registered(0) if $dxchan;
			push @out, $self->msg("regun", $call);
			Log('DXCommand', $self->call . " unregistered $call");
		} else {
			push @out, $self->msg('e3', 'unset/register', $call);
		}
	} else {
		Log('DXCommand', $self->call . " attempted to unregister $call remotely");
		push @out, $self->msg('sorry');
	}
}
return (1, @out);
