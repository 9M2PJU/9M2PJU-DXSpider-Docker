#
# set the email address  of the user
#
# Copyright (c) 1998 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

$line =~ s/[<>()\[\]{}]//g;  # remove any braces
my @f = split /\s+/, $line;

return (1, $self->msg('emaile1')) if !$line;

$user = DXUser::get_current($call);
if ($user) {
	$user->email(\@f);
	$user->wantemail(1);
	$user->put();
	return (1, $self->msg('emaila', $line));
} else {
	return (1, $self->msg('namee2', $call));
}

