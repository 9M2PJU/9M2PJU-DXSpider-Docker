#
# join a group (note this applies only to users)
#
# Copyright (c) 2003 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, uc $line;
my $group;
my @out;

my @group = @{$self->user->group};

foreach $group (@args) {
  push @group, $group unless grep $_ eq $group, @group; 
  push @out, $self->msg('join', $group);
}

$self->user->group(\@group);
$self->user->put;

return (1, @out);
