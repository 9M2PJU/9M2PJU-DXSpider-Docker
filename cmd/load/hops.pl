#
# load the node hop count table after changing it
#
my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
my @out = DXProt::load_hops($self);
@out = ($self->msg('ok')) if !@out;
return (1, @out); 
