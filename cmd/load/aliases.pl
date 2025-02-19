#
# load the Command Aliases file after changing it
#
my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
my @out = CmdAlias::load($self);
@out = ($self->msg('ok')) if !@out;
return (1, @out); 
