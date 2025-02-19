#
# set the talk flag
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
    $chan->talk(1);
    $chan->user->wanttalk(1);
	push @out, $self->msg('talks', $call);
  } else {
    push @out, $self->msg('e3', "Set Talk", $call);
  }
}
return (1, @out);
