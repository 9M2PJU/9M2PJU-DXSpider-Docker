#
# a universal message mangling routine which allows the sysop
# tinker with the properties of a message
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 6;

# a line is cmd, msgno, data 
my @f = split /\s+/, $line, 3;
my $cmd;
my $msgno;
my $data;

#$DB::single = 1;

$cmd = shift @f if @f && $f[0] =~ /^\w+$/;
$msgno = shift @f if @f && $f[0] =~ /^\d+$/;

# handle queuing
if ($cmd =~ /^qu/i && !$msgno) {
	DXMsg::queue_msg(0);
	return (1, $self->msg('msg1'));
}
if ($cmd =~ /^qu/i) {
	DXMsg::queue_msg(1);
	return (1, $self->msg('msg2'));
}

return (1, $self->msg('msgu')) unless $cmd && $msgno;
$data = shift @f;

# get me message
my $ref = DXMsg::get($msgno);
return (1, $self->msg('m13', $msgno)) unless $ref;

my $old;
my $new;
my $m;
if ($cmd =~ /^to/i) {
    $m = 'To';
	$old = $ref->to;
	$new = $ref->to(uc $data);
} elsif ($cmd =~ /^fr/i) {
    $m = 'From';
	$old = $ref->from;
	$new = $ref->from(uc $data);
} elsif ($cmd =~ /^pr/i) {
    $m = 'Msg Type';
	$old = $ref->private ? 'P' : 'B';
	$new = 'P';
	$ref->private(1);
} elsif ($cmd =~ /^nop/i || $cmd =~ /^bu/i) {
    $m = 'Msg Type';
	$old = $ref->private ? 'P' : 'B';
	$new = 'B';
	$ref->private(0);
} elsif ($cmd =~ /^re/i) {
    $m = 'Msg Type';
	$old = $ref->read ? 'Read' : 'Unread';
	$new = 'Read';
	$ref->read(1);
} elsif ($cmd =~ /^(nore|unre)/i) {
    $m = 'Msg Type';
	$old = $ref->read ? 'Read' : 'Unread';
	$new = 'Unread';
	$ref->read(0);
} elsif ($cmd =~ /^rr/i) {
    $m = 'RR Req';
	$old = $ref->rrreq ? 'RR Req' : 'No RR Req';
	$new = 'RR Req';
	$ref->rrreq(1);
} elsif ($cmd =~ /^norr/i) {
    $m = 'RR Req';
	$old = $ref->rrreq ? 'RR Req' : 'No RR Req';
	$new = 'No RR Req';
	$ref->rrreq(0);
} elsif ($cmd =~ /^ke/i) {
    $m = 'Keep';
	$old = $ref->keep ? 'Keep' : 'No Keep';
    $new = 'Keep';
	$ref->keep(1);
} elsif ($cmd =~ /^noke/i) {
    $m = 'Keep';
	$old = $ref->keep ? 'Keep' : 'No Keep';
    $new = 'No Keep';
    $ref->keep(0);
} elsif ($cmd =~ /^node/i) {
    $m = 'Delete';
	$old = $ref->delete ? 'Delete' : 'Not Delete';
    $new = 'Not Delete';
    $ref->unmark_delete;
} elsif ($cmd =~ /^su/i) {
    $m = 'Subject';
    $old = $ref->subject;
	$new = $ref->subject($data);
} elsif ($cmd =~ /^wa/i) {
    $m = 'Wait Time';
	$old = cldatetime($ref->waitt) || 'None';
	$new = 'None'; 
    $ref->waitt(0);
} else {
	return (1, $self->msg('e15', $cmd));
}

# store changes and return	
$ref->store( [ $ref->read_msg_body() ] );
return(1, $self->msg('msg3', $msgno, $m, $old, $new));



