#
# show who all the users are connected to
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @list = map { uc } split /\s+/, $line;           # list of callsigns of nodes
my @out;
my @users = sort {$a->call cmp $b->call} values %Route::User::list;

foreach my $uref (@users) {
	my $ucall = $uref->call;
	next if @list && !grep $ucall =~ m|$_|, @list;
	my $call = $uref->user_call;
	my $l = join ',', (map {my $ref = Route::Node::get($_); $ref ? ($ref->user_call) : ("$_?")} sort $uref->parents);
	push @out, "$call->$l";
}

return (1, @out);
