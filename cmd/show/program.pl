#
# show where I have included stuff from so far
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#
my $self = shift;
return (1, $self->msg('e5')) if $self->priv < 5;
my @in = sort keys %INC;
my @out = ("Locations of included Program Modules");
for (@in) {
	push @out, "$_ => $INC{$_}" if $INC{$_} =~ /spider/o;
} 

return (1, @out);
