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
return (1, $self->msg('e14')) unless defined $val;
return (1, $self->msg('e12')) unless @args;

if ($val =~ /^(\d+)[sS]$/) {
	$val = $1;
} elsif ($val =~ /^(\d+)[mM]$/) {
	$val = $1 * 60;
} elsif ($val =~ /^(\d+)[hH]$/) {
	$val = $1 * 60 * 60;
} elsif ($val =~ /^\d+$/) {
	$val *= 60 if $val < 30;
} else {
	return (1, $self->msg('e14'));
}

foreach $call (@args) {
	$call = uc $call;
	my $dxchan = DXChannel::get($call);
	$user = $dxchan->user if $dxchan;
	$user = DXUser::get($call) unless $user;
	if ($user) {
		unless ($user->is_node) {
			push @out, $self->msg('e13', $call);
			next;
		}
		$user->pingint($val);
		if ($dxchan) {
			$dxchan->pingint($val);
		} else {
			$user->close();
		}
		push @out, $self->msg('pingint', $call, $val);
	} else {
		push @out, $self->msg('e3', "Set/Pinginterval", $call);
	}
}
return (1, @out);
