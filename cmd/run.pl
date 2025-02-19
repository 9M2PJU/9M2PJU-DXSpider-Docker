#
# the run command
#
# run a script from the scripts directory
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @out;

while (@f) {
	my $f = shift @f;
	
	if (is_callsign(uc $f) && $self->priv < 8 && uc $f ne $self->call) {
		push @out, $self->msg('e5');
		next;
	}
	$f =~ s|[^-\w/\\]||g;
	my $script = new Script(lc $f);
	unless ($script) {
		push @out, $self->msg('e3', 'script', $f);
		next;
	}
	$script->run($self);
}

return (1, @out);

