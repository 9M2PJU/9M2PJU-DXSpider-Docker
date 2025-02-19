#
# Reload the DB list
#
my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 9;
DXDb::closeall();
DXDb::load();
return (1, 'Ok');
