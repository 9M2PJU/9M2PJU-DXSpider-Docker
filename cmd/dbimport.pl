#!/usr/bin/perl
#
# Database update routine
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
my ($self, $line) = @_;
my ($name, $fn) = split /\s+/, $line;
my @out;

return (1, $self->msg('e5')) if $self->priv < 9;

my $db = DXDb::getdesc($name);
return (1, $self->msg('db3', $name)) unless $db;
return (1, $self->msg('db1', $db->remote )) if $db->remote;
return (1, $self->msg('e3', 'dbimport', $fn)) unless -e $fn;

my $state = 0;
my $key;
my $value;
my $count;

open(IMP, $fn) or return (1, "Cannot open $fn $!");
while (<IMP>) {
	s/[\r\n]+$//g;
	if ($state == 0) {
		if (/^\&\&/) {
			$state = 0;
			next;
		}
		$key = uc $_;
		$value = undef;
		++$state if $key;
	} elsif ($state == 1) {
		if (/^\&\&/) {
			if ($key =~ /^#/) {
			} elsif ($key && $value) {
				$db->putkey($key, $value);
				$count++;
			}
			$state = 0;
			next;
		} elsif (/^\%\%/) {
			$state = 0;
			next;
		}
		$value .= $_ . "\n";
	}
}
close (IMP);

push @out, $self->msg('db10', $count, $fn, $db->name);
return (1, @out);
