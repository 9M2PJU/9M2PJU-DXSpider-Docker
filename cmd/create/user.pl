#
# create a user
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

return (1, $self->msg('e5')) if $self->priv < 9 || $self->remotecmd;

foreach $call (@args) {
	$call = uc $call;
	$user = DXUser::get($call);
	unless ($user) {
		$user = DXUser->new($call);
		$user->sort('U');
		$user->homenode($main::mycall);
		$user->close();
		push @out, $self->msg('creuser', $call);
	} else {
		push @out, $self->msg('hasha', $call, 'Users');
	}
}
return (1, @out);










