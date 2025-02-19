#
# unset AGW engine monitoring
#
#
#

my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 9;
if ($AGWMsg::monitor == 1) {
	AGWMsg::_sendf('m');
	$AGWMsg::monitor = 0;
	return (1, $self->msg('mond'));
}
return (1);
