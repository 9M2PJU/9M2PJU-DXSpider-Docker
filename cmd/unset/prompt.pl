#
# unset the prompt of the user
#
# Copyright (c) 2001 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

$user = DXUser::get_current($call);
if ($user) {
	delete $user->{prompt};
	delete $self->{prompt};
	$user->put();
	return (1, $self->msg('pru', $line));
} else {
	return (1, $self->msg('namee2', $call));
}

