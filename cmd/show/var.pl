#
# show any variable
#
# Rape me!
#
# Copyright (c) 1999 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 9 || $self->remotecmd || $self->inscript;
return (1, $self->msg('e9')) unless $line;
my @f = split /\s+/, $line;
my $f;
my @out;

foreach $f (@f) {
#    print "\$f = $f\n";
	my @in;
	push @in, (eval $f);
	if (@in) {
		push @out, "$f = ". dd(\@in);
		Log('DXCommand', $self->call . " show/var $f");
	} else {
		push @out, $@ ? $@ : $self->msg('e3', 'show/var', $f);
		Log('DXCommand', $self->call . " show/var $f not found" );
	}
}

return (1, @out);
