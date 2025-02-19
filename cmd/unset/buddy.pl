#
# remove a buddy from the list
#
# Copyright (c) 2006 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, uc $line;
my $buddies;
my @out;

my @buddies = @{$self->user->buddies};

foreach my $call (@args) {
	push(@out, $self->msg('e22', $call)), next unless is_callsign($call);
	next if $call eq $self->call;
	@buddies = grep $_ ne $call, @buddies; 
	push @out, $self->msg('buddyu', $call);
}

$self->user->buddies(\@buddies);
$self->user->put;

return (1, @out);
