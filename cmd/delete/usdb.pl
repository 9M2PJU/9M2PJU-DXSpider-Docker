#
# delete a usdb entry
#
# Please note that this may screw up everything to do with
# spotting onwards
#
# Copyright (c) 2002 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my @out;
my $user;

return (1, $self->msg('e5')) if $self->priv < 9;

foreach $call (@args) {
	USDB::del($call);
	push @out, $self->msg('susdb4', $call);
	Log('DXCommand', $self->msg('susdb4', $call));
}
return (1, @out);
