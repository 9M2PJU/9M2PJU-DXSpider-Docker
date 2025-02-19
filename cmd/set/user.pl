#
# set back to user
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
	if ($call eq $main::mycall) {
		push @out, $self->msg('e11', $call);
		next;
	}
	my $chan = DXChannel::get($call);
	if ($chan) {
		push @out, $self->msg('nodee1', $call);
	} else {
		$user = DXUser::get($call);
		return (1, $self->msg('usernf', $call)) if !$user;
		$user->sort('U');
		$user->priv(0);
		$user->close();
		push @out, $self->msg('nodeu', $call);
	}
}
return (1, @out);
