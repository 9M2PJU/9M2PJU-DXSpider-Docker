#
# delete a user
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

return (1, $self->msg('e5')) if $self->priv < 9;

foreach $call (@args) {
	$call = uc $call;
	my $chan = DXChannel::get($call);
	if ($chan) {
		push @out, $self->msg('nodee1', $call);
	} else {
		$user = DXUser::get($call);
		if ($user) {
			$user->del;
			push @out, $self->msg('deluser', $call);
			Log('DXCommand', $self->msg('deluser', $call));
		} else {
			push @out, $self->msg('e3', "Delete/User", $call);
		}
	}
}
return (1, @out);
