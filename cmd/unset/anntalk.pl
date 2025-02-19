#
# unset the allow talklike announce flag
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
    $chan->ann_talk(0);
    $chan->user->wantann_talk(0);
	push @out, $self->msg('anntu', $call);
  } else {
    push @out, $self->msg('e3', "Unset Ann_Talk", $call);
  }
}
return (1, @out);
