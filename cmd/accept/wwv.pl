#
# accept/reject filter commands
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my $type = 'accept';
my $sort  = 'wwv';

my ($r, $filter, $fno) = $Geomag::filterdef->cmd($self, $sort, $type, $line);
return (0, $r ? $filter : $self->msg('filter1', $fno, $filter->{name})); 
