#
# show the debug status
#
#
#

use DXDebug;

my $self = shift;
return (0) if ($self->priv < 9); # only console users allowed

my $set = join ' ', dbglist();   # generate space delimited list

return (1, "debug levels: $set");


