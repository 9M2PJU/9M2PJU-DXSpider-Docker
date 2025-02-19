#
# send the motd for this user
#

my ($self, $line) = @_;

$self->send_motd;

return (1);
