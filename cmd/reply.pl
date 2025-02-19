#
# send a message
#
# this should handle
#
# send <call> [<call> .. ]
# send private <call> [<call> .. ]
# send private rr <call> [<call> .. ]
# send rr <call> [<call> .. ]
# send noprivate <call> [<call> .. ]
# send b <call> [<call> .. ]
# send copy <call> [<call> .. ]
# send copy rr <call> [<call> .. ]
# 
# Copyright (c) Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my @out;
my $loc;

#$DB::single = 1;

if ($self->state eq "prompt") {
	
	my @f = split /\s+/, $line if $line;
	
	# now deal with real message inputs 
	# parse out send line for various possibilities
	$loc = {};
	
	my $i = 0;
	my @extra = ();
	my $msgno = $self->lastread;
	$loc->{private} = '1';
	$loc->{rrreq} = '0';
	while (@f) {
		my $w = shift @f;
		if ($w =~ /^\d+$/) {
			$msgno = $w;
		} elsif ($w =~ /^(B|NOP)/i) {
			$loc->{private} = '0';
		} elsif ($w =~ /^P/i) {
			;
		} elsif (uc $w eq 'RR') {
			$loc->{rrreq} = '1';
		} else {
			push @extra, uc $w;
		}
	}
	
	my $oref; 
	
	# check we have a reply number
	#  $DB::single = 1;
	
	$oref = DXMsg::get($msgno) if $msgno;
	return (1, $self->msg('m4', $i)) unless $oref;
	
	# now save all the 'to' callsigns for later
	my $to;
	if ($loc->{private}) {
		$to = $oref->from;
	} else {
		$to = $oref->to;
		@extra = ();
	} 

	return (1, $self->msg('e28')) unless $self->isregistered || $to eq $main::myalias;
	
	$loc->{to} = [ $to, @extra ];       # to is an array
	$loc->{subject} = $oref->subject;
	$loc->{subject} = "Re: " . $loc->{subject} if !($loc->{subject} =~ /^Re:\s/io); 
	
	# find me and set the state and the function on my state variable to
	# keep calling me for every line until I relinquish control
	$self->func("DXMsg::do_send_stuff");
	$self->state('sendbody');
	$self->loc($loc);
	push @out, $self->msg('m6', join(',', $to, @extra));
	push @out, $self->msg('m7', $loc->{subject});
	push @out, $self->msg('m8');
}

return (1, @out);
