#
# set the maximum no of connections this user/node can have
# whilst connecting to this node
#
# Copyright (c) 2008 - Dirk Koopman G1TLH
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my @out;
my $user;
my $val = shift @args if @args;


return (1, $self->msg('e5')) if $self->priv < 8;
return (1, $self->msg('e14')) unless defined $val;
return (1, $self->msg('e12')) unless @args;

foreach $call (@args) {
	$call = uc $call;
	$user = DXUser::get_current($call);
	if ($user) {
		$user->maxconnect($val);
		$user->put;
		push @out, $self->msg('maxconnect', $call, $val);
	} else {
		push @out, $self->msg('e3', "set/maxconnect", $call);
	}
}
return (1, @out);
