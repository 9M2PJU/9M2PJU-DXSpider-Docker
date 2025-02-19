#
# kill or delete a message
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

use strict;

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $msgno;
my @out;
my @body;
my $ref;
my @refs;
my $call = $self->call;
my $full;
my $expunge;

# $DB::single = 1;

while (@f) {
	my $f = shift @f;
	if ($f =~ /^fu/io) {
		return (1, $self->msg('e5')) if $self->priv < 5;
		$full = 1;
	} elsif ($f =~ /^ex/io) {
		return (1, $self->msg('e5')) if $self->priv < 6;
		$expunge = 1;
	} elsif ($f =~ /^\d+$/o) {
		$ref = DXMsg::get($f);
		if (!$ref) {
			push @out, "Msg $f not found";
			next;
		}
		if ($self->priv < 5 && $ref->to ne $call && $ref->from ne $call) {
			push @out, "Msg $f not available";
			next;
		} 
		push @refs, $ref;
	} elsif ($f =~ /(\d+)-(\d+)/) {
		my $from = $1;
		my $to = $2;
		@refs = grep { !($self->priv < 5 && $_->to ne $call && $_->from ne $call) } DXMsg::get_all() unless @refs;
		@refs = grep { $_->msgno >= $from && $_->msgno <= $to } @refs;
	} elsif ($f =~ /^fr/io) {
		$f = shift @f;
		if ($f) {
			$f = shellregex($f);
			@refs = grep { !($self->priv < 5 && $_->to ne $call && $_->from ne $call) } DXMsg::get_all() unless @refs;
			@refs = grep { $_->from =~ m{$f}i } @refs;
		}
	} elsif ($f =~ /^to/io) {
		$f = shift @f;
		if ($f) {
			$f = shellregex($f);
			@refs = grep { !($self->priv < 5 && $_->to ne $call && $_->from ne $call) } DXMsg::get_all() unless @refs;
			@refs = grep { $_->to =~ m{$f}i } @refs;
		}
	} else {
		push @out, "invalid argument '$f'";
		return (1, @out);
	}
}

foreach $ref ( @refs) {
	if ($ref->keep) {
		push @out, $self->msg('m18', $ref->msgno);
		next;
	}
	my $tonode = $ref->tonode;
	$ref->stop_msg($tonode) if $tonode;
	$ref->mark_delete($expunge ? 0 : undef);
	push @out, $self->msg('m12', $ref->msgno);
	Log('msg', "Message $ref->{msgno} from $ref->{from} to $ref->{to} deleted by $call");
	if ($full) {
		DXChannel::broadcast_nodes(DXProt::pc49($ref->{from}, $ref->{subject}), $main::me);
	}
}

return (1, @out);
