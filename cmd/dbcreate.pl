#!/usr/bin/perl
#
# Database update routine
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $name = shift @f if @f;
my @out;

return (1, $self->msg('e5')) if $self->priv < 9;
return (1, $self->msg('db6', $name)) if DXDb::getdesc($name);

my $remote;
my $chain;
my $cmd;
while (@f) {
	my $f = lc shift @f;
	if ($f eq 'remote') {
		$remote = uc shift @f if @f;
		next;
	}
	if ($f eq 'cmd') {
		$cmd = lc shift @f if @f;
		next;
	}
	if ($f eq 'chain') {
		if (@f) {
			$chain = [ @f ];
			last;
		}
	}
}
DXDb::new($name, $remote, $chain, $cmd);
push @out, $self->msg($remote ? 'db7' : 'db8', $name, $remote);
return (1, @out);
