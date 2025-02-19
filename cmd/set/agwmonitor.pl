#
# set AGW engine monitoring
#
#
#

my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
if ($AGWMsg::monitor == 0) {
	AGWMsg::_sendf('m');
	$AGWMsg::monitor = 1;
	return (1, $self->msg('mone'));
}
return (1);



