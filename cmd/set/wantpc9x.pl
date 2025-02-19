#
# set the wantPC9x flag
#
# Copyright (c) 2007 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, uc $line;
my $call;
my @out;

return (1, $self->msg('e5')) if $self->priv < 9;

foreach $call (@args) {
	return (1, $self->msg('e12')) unless is_callsign($call);

	my $user = DXUser::get_current($call);
	if ($user) {
		$user->wantpc9x(1);
		$user->put;
		push @out, $self->msg('wpc9xs', $call);
	} else {
		push @out, $self->msg('e3', "set/wantpc9x", $call);
	}
}
return (1, @out);
