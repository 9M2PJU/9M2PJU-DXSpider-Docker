#
# leave a group
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
  @group = grep $_ ne $group, @group; 
  push @out, $self->msg('leave', $group);
}

$self->user->group(\@group);
$self->user->put;

return (1, @out);
