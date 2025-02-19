#
# show the users on this cluster from the routing tables
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @list = map { uc } split /\s+/, $line; # list of callsigns of nodes
my @out;

if (@list) {
	foreach my $call (sort @list) {
		my $uref = DXUser::get_current($call);
		if ($uref) {
			my $name = $uref->name || '?';
			my $qth = $uref->qth || '?';
			my $qra = $uref->qra || '';
			my $route = '';
			if (my $rref = Route::get($call)) {
				$route = '(at ' . join(',', $rref->parents) . ')';
			}
			push @out, "$call $route $name $qth $qra",
		} else {
			push @out, $self->msg('usernf', $call);
		}
	}
} else {
	my $node = $main::routeroot;
	push @out, join(' ', $self->msg('userconn'), $main::mycall);
	my $call;
	my @l;
	my @val = sort $node->users;
	foreach $call (@val) {
		if (@l >= 5) {
			push @out, sprintf "%-12s %-12s %-12s %-12s %-12s", @l;
			@l = ();
		}
		my $uref = Route::User::get($call);
		my $s = $call;
		if ($uref) {
			$s = sprintf "(%s)", $call unless $uref->here;
		} else {
			$s = "$call?";
		}
		push @l, $s;
	}
	push @l, "" while @l < 5;
	push @out, sprintf "%-12s %-12s %-12s %-12s %-12s", @l;
}

return (1, @out);

