#
# remove a debug level
#
# Copyright (c) 1998 - Dirk Koopman 
#
#
#

my ($self, $line) = @_;
return (0) if $self->priv < 9;

dbgsub(split /\s+/, $line);
my $set = join ' ', dbglist();

return (1, "Debug Levels now: $set"); 
