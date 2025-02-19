#!/usr/bin/perl
#
# Database export routine
#
# Copyright (c) 2010 Dirk Koopman G1TLH
#
my ($self, $line) = @_;
my ($name, $fn) = split /\s+/, $line;
return (1, $self->msg('e5')) if $self->priv < 9;
return (1, "dbexport: <database name> <pathname to export to>") unless $name && $fn;

my @out;

my $db = DXDb::getdesc($name);
return (1, $self->msg('db3', $name)) unless $db;
return (1, $self->msg('db1', $db->remote )) if $db->remote;
my $of = IO::File->new(">$fn") or return(1, $self->msg('e30', $fn));

$db->open;						# make sure we are open
my ($r, $k, $v, $flg, $count);
for ($flg = R_FIRST; !$db->{db}->seq($k, $v, $flg); $flg = R_NEXT) {
	$of->print("$k\n$v\&\&\n");
	++$count;
}
$of->close;
return(0, $self->msg("db13", $count, $name, $fn));



