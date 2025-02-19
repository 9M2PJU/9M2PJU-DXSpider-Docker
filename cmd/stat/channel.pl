#
# show the channel status
#
#
#

use strict;
my ($self, $line) = @_;
my @list = split /\s+/, $line;		  # generate a list of callsigns
@list = ($self->call) if !@list || $self->priv < 1;  # my channel if no callsigns

my $call;
my @out;
foreach $call (@list) {
  $call = uc $call;
  my $ref = DXChannel::get($call);
  if ($ref) {
    @out = print_all_fields($self, $ref, "Channel Information $call");
  } else {
    return (0, "Channel: $call not found") if !$ref;
  }
  push @out, "" if @list > 1;
}

return (1, @out);


