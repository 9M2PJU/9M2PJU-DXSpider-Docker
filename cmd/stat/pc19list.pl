#
# list out the PC19s that are outstanding (for which PC16s have not been seen)
#
# Copyright (c) 2003 Dirk Koopman G1TLH
#
#
#

my $self = shift;
return (1, $self->msg('e5')) unless $self->priv >= 9;

my @patt = map {"^\Q$_"} split /\s+/, uc shift;
my @out;

foreach my $k (sort keys %DXProt::pc19list) {
	if (!@patt || grep $k =~ /$_/, @patt) {
		my $nl = $DXProt::pc19list{$k};
		push @out, "$k: " . join (', ', map {"via $_->[0]($_->[1] $_->[2])"} @$nl);
	}
}

return (1, @out);

