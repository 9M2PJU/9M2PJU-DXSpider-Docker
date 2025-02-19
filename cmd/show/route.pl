#
# show the routing to a node or station
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @list = map { uc } split /\s+/, $line;           # list of callsigns of nodes
my @out;

return (1, $self->msg('e6')) unless @list;

my $l;
foreach $l (@list) {
	my $ref = Route::get($l);
	if ($ref) {
		my $parents = $ref->isa('Route::Node') ? $l : join(',', $ref->parents);
		my @n = map { $_->[1]->call . '(' .  (100 - $_->[0]) . ')' } Route::findroutes($l);
		@n = (@n[0,1,2,3],'...') if @n > 4;
		push @out, $self->msg('route', $l, $parents,  join(',', @n));
	} else {
		push @out, $self->msg('e7', $l);
	}
}

return (1, @out);
