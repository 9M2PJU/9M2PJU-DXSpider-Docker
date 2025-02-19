#
# unset the dx flag
#
# Copyright (c) 1998 - Dirk Koopman
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
  my $chan = DXChannel::get($call);
  if ($chan) {
    $chan->dx(0);
	$chan->user->wantdx(0);
	push @out, $self->msg('dxu', $call);
  } else {
    push @out, $self->msg('e3', "Unset DX Spots", $call);
  }
}
return (1, @out);
