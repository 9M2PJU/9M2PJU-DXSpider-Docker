#
# set the wx flag
#
# Copyright (c) 1999 - Dirk Koopman
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
    $chan->wx(1);
    $chan->user->wantwx(1);
	push @out, $self->msg('wxs', $call);
  } else {
    push @out, $self->msg('e3', "Set WX Spots", $call);
  }
}
return (1, @out);
