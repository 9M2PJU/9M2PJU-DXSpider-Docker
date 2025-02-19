#
# set the ve7cc output flag
#
# Copyright (c) 2000 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my @args = split /\s+/, $line;
my $call;
my @out;

return (0, $self->msg('e5')) unless $self->isa('DXCommandmode');
$self->ve7cc(0);
push @out, $self->msg('ok');
return (1, @out);
