#
# the shutdown command
# 
#
#
my $self = shift;
my $call = $self->call;
my $ref;
return (1, $self->msg('e5')) unless $self->priv >= 5;
foreach $ref (DXChannel::get_all()) {
	$ref->send($self->msg('shutting')) if $ref->is_user;
}
    
# give some time for the buffers to empty and then shutdown (see cluster.pl)
$main::decease = 25;

return (1);
