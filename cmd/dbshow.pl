#!/usr/bin/perl
#
# Database enquiry routine
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @out;

my $name = shift @f if @f;
my $db = DXDb::getdesc($name);
return (1, $self->msg('db3', $name)) unless $db;

my @db; 
push @db, $name;
push @db, @{$db->chain} if $db->chain;

my $n;
foreach  $n (@db) {
	$db = DXDb::getdesc($n);
	return (1, $self->msg('db3', $n)) unless $db;
	
	if ($db->remote) {

		# remote databases
		unless (Route::Node::get($db->remote) || DXChannel::get($db->remote)) {
			push @out, $self->msg('db4', uc $name, $db->remote);
			last;
		}
		
		push @out, $self->msg('db11', $db->remote);
		push @f, " " unless @f;
		for (@f) {
			my $n = DXDb::newstream($self->call);
			DXProt::route(undef, $db->remote, DXProt::pc44($main::mycall, $db->remote, $n, uc $db->name,uc $_, $self->call));
		}
#		last;
	} else {

		# local databases can chain to remote ones
		my $count;
		my $pre = $db->print('pre');
		push @out, $pre if defined $pre;
#		push @out, "@f";
		for (@f) {
			push @out, $db->name . " $_";
			my $value = $db->getkey($_) || "";
#			push @out, $db->name . ": $_ :";
			if ($value) {
				push @out, split /\n/, $value;
				$count++;
			} else {
				push @out, $self->msg('db2', uc $_, uc $db->{name});
			}
		}
		if ($count) {
			my $post = $db->print('post');
			push @out, $post if $post;
#			last;
		}
	}
}

return (1, @out);
