#
# set the usstate flag
#
# Copyright (c) 2000 - Dirk Koopman
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
		$user->wantusstate(1);
#		if ($user->wantdxitu) {
#			push @out, $self->msg('dxituu', $call);
#			$user->wantdxitu(0);
#		}
#		if ($user->wantdxcq) {
#			push @out, $self->msg('dxcqu', $call);
#			$user->wantdxcq(0);
#		}
		$user->put;
		push @out, $self->msg('usstates', $call);
	} else {
		push @out, $self->msg('e3', "Set US State", $call);
	}
}
return (1, @out);
