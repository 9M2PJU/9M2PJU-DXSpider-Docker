#
# unset the email address  of the user
#
# Copyright (c) 2001 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

$user = DXUser::get_current($call);
if ($user) {
	$user->wantemail(0);
	$user->put();
	return (1, $self->msg('emaila', $line));
} else {
	return (1, $self->msg('namee2', $call));
}

