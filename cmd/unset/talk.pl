#
# unset the talk flag
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
    $chan->talk(0);
	$chan->user->wanttalk(0);
	push @out, $self->msg('talku', $call);
  } else {
    push @out, $self->msg('e3', "Unset Talk", $call);
  }
}
return (1, @out);
