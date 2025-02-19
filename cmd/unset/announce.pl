#
# set the announce flag
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
    $chan->ann(0);
	$chan->user->wantann(0);
	push @out, $self->msg('annu', $call);
  } else {
    push @out, $self->msg('e3', "Unset Announce", $call);
  }
}
return (1, @out);
