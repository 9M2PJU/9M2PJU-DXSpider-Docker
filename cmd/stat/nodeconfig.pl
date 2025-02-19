#
# show who all the nodes are connected to
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @list = map { uc } split /\s+/, $line;           # list of callsigns of nodes
my @out;
my @nodes = sort {$a->call cmp $b->call} values %Route::Node::list;

foreach my $nref (@nodes) {
	my $ncall = $nref->call;
	next if @list && !grep $ncall =~ m|$_|, @list;
	my $call = $nref->user_call;
	my $l = join ',', (map {my $ref = Route::Node::get($_); $ref ? ($ref->user_call) : ("$_?")} sort $nref->parents);
	push @out, "$call->$l";
}

return (1, @out);
