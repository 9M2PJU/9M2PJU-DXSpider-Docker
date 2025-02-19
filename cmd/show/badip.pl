#
# set list of bad dx nodes
#
# Copyright (c) 2021 - Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->remotecmd;
# are we permitted?
return (1, $self->msg('e5')) if $self->priv < 6;
my @out;
my @added;
my @in = split /\s+/, $line;
my @list= DXCIDR::list();
foreach my $list (@list) {
	if (@in) {
		for (@in) {
			if ($list =~ /$_/i) {
				push @out, $list;
				last;
			}
		}
	} else {
		push @out, $list;
	} 
}
return (1, @out);
