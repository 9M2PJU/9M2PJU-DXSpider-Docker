#
# the type command, display bulls and files
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $root = "$main::root/packclus";
my @out;
my @file;
my @d;
my @slot;

if (@f) {
	my $fn = lc $f[0];
	$fn =~ s([^A-Za-z0-9_/])()g;
	$fn =~ s(^/+)();
	$root = "$root/$fn";
}

open(INP, $root) or return (1, $self->msg('e3', 'type', $f[0]));
@out = <INP>;
close(INP);

return (1, @out);
