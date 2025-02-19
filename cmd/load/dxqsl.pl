#
# load the QSL file after changing it
#
my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
my $r = QSL::init(1);
return (1, $r ? $self->msg('ok') : $self->msg('e2', "$!"));
