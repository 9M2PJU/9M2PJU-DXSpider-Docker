#
# show your buddies 
#
# Copyright (c) 2006 - Dirk Koopman G1TLH
#
#
#

my ($self) = @_;
my $buddies = $self->user->buddies || [];
my @out;
my @l;

foreach my $call (@$buddies) {
	if (@l >= 5) {
		push @out, sprintf "%-12s %-12s %-12s %-12s %-12s", @l;
		@l = ();
	}
	push @l, $call;
}
push @l, "" while @l < 5;
push @out, sprintf "%-12s %-12s %-12s %-12s %-12s", @l;
return (1, @out);
