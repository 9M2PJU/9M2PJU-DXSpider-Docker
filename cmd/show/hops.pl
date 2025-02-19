#
# show hops commands
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @out;
my $call = $self->call;

if (@f && $self->priv >= 8) {
	if (is_callsign(uc $f[0])) {
		$call = uc shift @f;
    } elsif ($f[0] eq 'node_default' || $f[0] eq 'user_default') {
		$call = shift @f;
	}
}

my @in;
if (@f) {
	push @in, @f;
} else {
	push @in, qw(ann spots route wcy wwv);
}

my $sort;
foreach $sort (@in) {
	my $ref = Filter::read_in($sort, $call, 0);
	my $hops = $ref ? $ref->{hops} : undef;
	push @out, $self->msg('sethop2', $hops, '', $sort, $call) if $hops;
}
push @out, $self->msg('sethop3', $call) unless @out;
return (1, @out);
