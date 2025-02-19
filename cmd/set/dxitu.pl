#
# set the dxitu flag
#
# Copyright (c) 2000 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my @out;

@args = $self->call if (!@args || $self->priv < 9);

foreach $call (@args) {
	$call = uc $call;
	my $user = DXUser::get_current($call);
	if ($user) {
		$user->wantdxitu(1);
#		if ($user->wantdxcq) {
#			push @out, $self->msg('dxcqu', $call);
#			$user->wantdxcq(0);
#		}
		if ($user->wantusstate) {
			push @out, $self->msg('usstateu', $call);
			$user->wantusstate(0);
		}
		$user->put;
		push @out, $self->msg('dxitus', $call);
	} else {
		push @out, $self->msg('e3', "Set DX ITU", $call);
	}
}
return (1, @out);
