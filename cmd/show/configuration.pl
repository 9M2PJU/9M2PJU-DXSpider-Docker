#
# show the cluster routing tables to the user
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @list = map { uc } split /\s+/, $line;           # list of callsigns of nodes
my @out;
my @nodes = sort {$a->call cmp $b->call} (Route::Node::get_all());
my $node;
my @l;
my @val;

push @out, $self->msg('showconf');
if ($list[0] && $list[0] =~ /^NOD/) {
	my %ch;
	my $dxchan;
	
	foreach my $n (@nodes) {
		$dxchan = $n->dxchan;
		push @{$ch{$dxchan->call}}, $n if $dxchan;
	}

	foreach my $call (sort keys %ch) {
		@val = sort {$a->call cmp $b->call} @{$ch{$call}};
		@l = ();
		$call = "($call)" unless DXChannel::get($call)->here;
		push @l, $call;
		
		foreach my $ref (@val) {
			if (@l >= 6) {
				push @out, sprintf "%-12s %-12s %-12s %-12s %-12s %-12s", @l;
				@l = ();
				push @l, "";
			}
			my $s = $ref->call;
			$s ||= '???';
			$s = sprintf "(%s)", $s unless $ref->here;
			push @l, $s;
		}
		push @l, "" while @l < 6;
		push @out, sprintf "%-12s %-12s %-12s %-12s %-12s %-12s", @l;
	}
} else {
	my $printall;
	
	$printall = 1 if @list && $list[0] =~ /^ALL/i;
	
	# build up the screen from the Node table
	foreach $node (@nodes) {
		unless ($printall) {
			if (@list) {
				next unless grep $node->call =~ /^$_/, @list;
			} else {
				next unless grep $node->dxcc == $_, @main::my_cc;
			}
		}
		my $call = $node->call;
		@l = ();
		$call ||= '???';
		$call = "($call)" unless $node->here;
		push @l, $call;
		@val = sort $node->users;

		if (@val == 0 && $node->usercount) {
			push @l, sprintf "(%d users)", $node->usercount;
		}
		foreach $call (@val) {
			if (@l >= 6) {
				push @out, sprintf "%-12s %-12s %-12s %-12s %-12s %-12s", @l;
				@l = ();
				push @l, "";
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
		push @l, "" while @l < 6;
		push @out, sprintf "%-12s %-12s %-12s %-12s %-12s %-12s", @l;
	}
}



return (1, @out);
