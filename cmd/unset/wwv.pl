#
# unset the wwv flag
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
    DXChannel::wwv($chan, 0);
    $chan->user->wantwwv(0);
	push @out, $self->msg('wwvu', $call);
  } else {
    push @out, $self->msg('e3', "Unset WWV", $call);
  }
}
return (1, @out);
