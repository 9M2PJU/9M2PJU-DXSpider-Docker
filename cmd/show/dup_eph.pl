#
# show a list of all the outstanding announce dups
# for debugging really
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#
my $self = shift;
my $line = shift;
return (1, $self->msg('e5')) unless $self->priv >= 9; 
my $regex = $line;
my @out;
my %list = DXProt::eph_list();

for (keys %list ) {
	if ($regex) {
		next unless /$regex/i;
	}
	push @out, ztime($list{$_}) . ": $_";
}
return (1, sort @out);

