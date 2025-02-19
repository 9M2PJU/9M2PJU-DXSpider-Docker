#
# set the wcy flag
#
# Copyright (c) 2001 - Dirk Koopman
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
    DXChannel::wcy($chan, 1);
    $chan->user->wantwcy(1);
	push @out, $self->msg('wcys', $call);
  } else {
    push @out, $self->msg('e3', "Set WCY", $call);
  }
}
return (1, @out);
