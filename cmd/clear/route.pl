#
# clear filters commands
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @out;
my $dxchan = $self;
my $sort = 'route';
my $flag;
my $fno = 1;
my $call = $dxchan->call;
my $f;

if ($self->priv >= 8) {
	if (@f && is_callsign(uc $f[0])) {
		$f = uc shift @f;
		my $uref = DXUser::get($f);
		$call = $uref->call if $uref;
	} elsif (@f && lc $f[0] eq 'node_default' || lc $f[0] eq 'user_default') {
		$call = lc shift @f;
	}
	if (@f && $f[0] eq 'input') {
		shift @f;
		$flag = 'in';
	}
}

$fno = shift @f if @f && $f[0] =~ /^\d|all$/;

my $filter = Filter::read_in($sort, $call, $flag);
Filter::delete($sort, $call, $flag, $fno);
$flag = $flag ? "input " : "";
push @out, $self->msg('filter4', $flag, $sort, $fno, $call);
return (1, @out);
