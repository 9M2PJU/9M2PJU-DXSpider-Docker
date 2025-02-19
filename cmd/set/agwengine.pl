#
# set AGW engine on
#
#
#

my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
unless ($AGWMsg::enable) {
	$AGWMsg::enable = 1;
	AGWMsg::init();
	return (1, $self->msg('agwe'));
}
return (1);

