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
return (1, "set/badip: need IP, IP-IP or IP/24") unless @in;
for (@in) {
	eval{ DXCIDR::add($_); };
	return (1, "set/badip: $_ $@") if $@;
	push @added, $_; 
}
my $count = @added;
my $list = join ' ', @in;
push @out, "set/badip: added $count entries: $list";
return (1, @out);
