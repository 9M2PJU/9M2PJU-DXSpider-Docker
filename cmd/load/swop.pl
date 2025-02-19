# reload the swop file
my $self = shift;
my @out;
return (1, $self->msg('e5')) if $self->priv < 9;
push @out, (DXMsg::load_swop());
@out = ($self->msg('ok')) unless @out;
return (1, @out); 
