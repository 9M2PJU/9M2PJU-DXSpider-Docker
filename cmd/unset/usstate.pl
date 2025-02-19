#
# unset the usstate flag
#
# Copyright (c) 2003 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my @out;

return (1, $self->msg('db3', 'FCC USDB')) unless $USDB::present;

@args = $self->call if (!@args || $self->priv < 9);

foreach $call (@args) {
	$call = uc $call;
	my $user = DXUser::get_current($call);
	if ($user) {
		$user->wantusstate(0);
		$user->put;
		push @out, $self->msg('usstateu', $call);
	} else {
		push @out, $self->msg('e3', "Unset US State", $call);
	}
}
return (1, @out);
