#
# set the address field
#
# Copyright (c) 1998 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my $call;
my @out;
my $user;

$user = $self->user;
$line =~ s/[{}]//g;   # no braces allowed
$user->addr($line);
push @out, $self->msg('addr', $line);

return (1, @out);
