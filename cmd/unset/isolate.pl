#
# set user type BACK TO  'U' (user)
#
# Please note that this is only effective if the user is not on-line
#
# Copyright (c) 1998 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my @out;
my $user;
my $create;

return (1, $self->msg('e5')) if $self->priv < 5;

foreach $call (@args) {
	$call = uc $call;
	my $chan = DXChannel::get($call);
	if ($chan) {
		push @out, $self->msg('nodee1', $call);
	} else {
		$user = DXUser::get($call);
		return (1, $self->msg('usernf', $call)) if !$user; 
		$user->isolate(0);
		$user->close();
		push @out, $self->msg('isou', $call);
		Log('DXCommand', $self->msg('isou', $call));
	}
}
return (1, @out);
