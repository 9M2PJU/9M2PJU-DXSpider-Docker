#
# Add/modify a USDB entry
#
# There are no checks and NO balances.
#
# Copyright (c) 2002 Dirk Koopman
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 9;

my ($call, $state, $city) = split /\s+/, uc $line, 3;
return (1, $self->msg('susdb1')) if length $state != 2 || !is_callsign($call);

my ($ocity, $ostate) = USDB::get($call);
my @out;
push @out, $self->msg('susdb2', $call, $ocity, $ostate ) if $ocity;
USDB::add($call, $city, $state);
push @out, $self->msg('susdb3', $call, $city, $state );
Log('DXCommand', $self->msg('susdb3', $call, $city, $state));
return (1, @out);

