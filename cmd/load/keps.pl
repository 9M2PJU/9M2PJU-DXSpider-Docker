#
# load the the keps file after changing it
#
my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 5;

if ($line =~ /^(\d+)$/) {
	my $msgno = $1;
	my $mref = DXMsg::get($msgno);
	return (1, $self->msg('m4', $msgno)) unless $mref;
	return (1, $self->msg('sat5')) unless $mref->subject =~ /\b\d{3,6}\.AMSAT\b/i;
	my $fn = DXMsg::filename($msgno);
	my $fh = new IO::File "$main::root/perl/convkeps.pl $fn |";
	my @in = <$fh>;
	$fh->close;
	return (1, @in) if @in;
}
my @out = Sun::load($self);
@out = ($self->msg('ok')) if !@out;
return (1, @out); 
