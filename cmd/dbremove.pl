#!/usr/bin/perl
#
# Database update routine
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
my ($self, $line) = @_;
my ($name) = split /\s+/, $line;
my @out;

return (1, $self->msg('e5')) if $self->priv < 9;
my $db = DXDb::getdesc($name);

return (1, $self->msg('db3', $name)) unless $db;
$db->delete;
push @out, $self->msg('db9', $name);

return (1, @out);
