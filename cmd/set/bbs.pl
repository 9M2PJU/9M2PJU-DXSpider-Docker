#
# set user type to 'B' for BBS node
#
# Please note that this is only effective if the user is not on-line
#
# Copyright (c) 2001 - Dirk Koopman
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
	if ($call eq $main::myalias) {
		push @out, $self->msg('e11', $call);
		next;
	}
	my $chan = DXChannel::get($call);
	if ($chan) {
		push @out, $self->msg('nodee1', $call);
	} else {
		$user = DXUser::get($call);
		$create = !$user;
		$user = DXUser->new($call) if $create;
		if ($user) {
			$user->sort('B');
			$user->homenode($call);
			$user->close();
			push @out, $self->msg($create ? 'nodecc' : 'nodec', $call);
		} else {
			push @out, $self->msg('e3', "Set BBS", $call);
		}
	}
}
return (1, @out);
