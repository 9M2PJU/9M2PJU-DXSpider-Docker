#
# check the privilege of the user is at least n
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @out;
$line = '1' unless defined $line;
push @out, $self->msg('e5') unless $line =~ /^\d+$/ && $self->priv >= $line;
return (1, @out);

