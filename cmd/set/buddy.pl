#
# add a buddy 
#
# Copyright (c) 2006 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, uc $line;
my $group;
my @out;

my $buddies = $self->user->buddies || [];

foreach my $call (@args) {
	push(@out, $self->msg('e22', $call)), next unless is_callsign($call);
	next if $call eq $self->call;
	push @$buddies, $call unless grep $_ eq $call, @$buddies; 
	push @out, $self->msg('buddya', $call);
}

$self->user->put;

return (1, @out);
