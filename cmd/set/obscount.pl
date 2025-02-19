#
# set ping interval for this node
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
my $val = shift @args if @args;


return (1, $self->msg('e5')) if $self->priv < 8;
return (1, $self->msg('e25', 1, 9)) unless defined $val && $val =~ /^\d+$/ && $val >= 1 && $val <= 9;
return (1, $self->msg('e12')) unless @args;

foreach $call (@args) {
	$call = uc $call;
	my $dxchan = DXChannel::get($call);
	$user = $dxchan->user if $dxchan;
	$user = DXUser::get_current($call);
	if ($user) {
		unless ($user->is_node) {
			push @out, $self->msg('e13', $call);
			next;
		}
		$user->nopings($val);
		if ($dxchan) {
			$dxchan->nopings($val);
		} else {
			$user->close();
		}
		push @out, $self->msg('obscount', $call, $val);
	} else {
		push @out, $self->msg('e3', "set/obscount", $call);
	}
}
return (1, @out);
