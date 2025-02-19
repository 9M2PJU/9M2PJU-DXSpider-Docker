#
# unset the dxdxitu flag
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
		$user->wantdxitu(0);
		$user->put;
		push @out, $self->msg('dxituu', $call);
	} else {
		push @out, $self->msg('e3', "Unset DX ITU", $call);
	}
}
return (1, @out);
