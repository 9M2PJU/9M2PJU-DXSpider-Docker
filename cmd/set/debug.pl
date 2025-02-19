#
# add a debug level
#
#
#

my ($self, $line) = @_;
return (0) if $self->priv < 9;

dbgadd(split /\s+/, $line);
my $set = join ' ', dbglist();

return (1, "Debug Levels now: $set"); 
