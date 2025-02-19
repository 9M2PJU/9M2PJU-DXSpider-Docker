#
# read a message
#
# Copyright (c) Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $msgno;
my @out;
my @body;
my $ref;

# if there are no specified message numbers, try and find a private one
# that I haven't read yet
if (@f == 0) {
	foreach $ref (DXMsg::get_all()) {
		if ($ref->to eq $self->call && $ref->private && !$ref->read && !$ref->delete) {
			push @f, $ref->msgno;
			last;
		}
	}
}

return (1, $self->msg('read1')) if @f == 0;

for $msgno (@f) {
	$ref = DXMsg::get($msgno);
	if (!$ref) {
		push @out, $self->msg('read2', $msgno);
		next;
	}
	if ($self->priv < 5 && $ref->private && $ref->to ne $self->call && $ref->from ne $self->call ) {
		push @out, $self->msg('read3', $msgno);
		next;
	}
	push @out, sprintf "Msg: %d From: %s Date: %6.6s %5.5s Subj: %-30.30s", $msgno,
		$ref->from, cldate($ref->t), ztime($ref->t), $ref->subject;
	@body = $ref->read_msg_body;
	push @out, @body;
	
	# mark it as read
	unless ($ref->private && $ref->to ne $self->call) {
		$ref->read($ref->read() + 1);
		$ref->store(\@body);    # note call by reference!

		# if it had a read receipt on it generate a new message to send back to
		# the sender.
		if ($ref->rrreq) {
			my $sub = $ref->subject;
			$sub = "Re: $sub" unless $sub =~ /^\s*re:/i;
			my $to = $ref->to;
			my $from = $ref->from;
			my $rref = DXMsg->alloc(1, $from, $main::mycall, time, 
									1, $sub, $main::mycall, 0, 0 );
			my $msgno = DXMsg::next_transno("Msgno");
			$rref->msgno($msgno);
			$rref->gotit( [ "$main::mycall" ] );
			$rref->store( [ "Return receipt from delivering node. Message read by $to." ] );
			DXMsg::add_dir($rref);
			DXMsg::queue_msg(0);
		}
	
		# remember this one as the last one read
		$self->lastread($msgno);
	}
}

return (1, @out);


