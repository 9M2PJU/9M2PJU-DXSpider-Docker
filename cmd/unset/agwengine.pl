#
# set AGW engine off
#
#
#

my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
if ($AGWMsg::enable) {
	AGWMsg::finish() if $AGWMsg::sock;
	$AGWMsg::enable = 0;
	return (1, $self->msg('agwu'));
}
return (1);
