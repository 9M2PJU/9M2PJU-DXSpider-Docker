#
# set isolation for this node
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

return (1, $self->msg('e5')) if $self->priv < 9;

foreach $call (@args) {
	$call = uc $call;
	my $chan = DXChannel::get($call);
	if ($chan) {
		push @out, $self->msg('nodee1', $call);
	} else {
		$user = DXUser::get($call);
		$create = !$user;
		$user = DXUser->new($call) if $create;
		my $f;
		push(@out, $self->msg('isoari', $call)), $f++ if Filter::getfn('route', $call, 1);
		push(@out, $self->msg('isoaro', $call)), $f++ if Filter::getfn('route', $call, 0);
		if ($user) {
			unless ($f) {
				$user->isolate(1);
				$user->close();
				push @out, $self->msg($create ? 'isoc' : 'iso', $call);
				Log('DXCommand', $self->msg($create ? 'isoc' : 'iso', $call));
			}
		} else {
			push @out, $self->msg('e3', "Set/Isolate", $call);
		}
	}
}
return (1, @out);
