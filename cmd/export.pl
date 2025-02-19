#
# export a message
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
my $fn;

return (1, $self->msg("e5")) if $self->priv < 9 || $self->consort ne 'local' || $self->remotecmd || $self->inscript;

return (1, $self->msg("export1")) unless @f == 2 && $f[0] =~ /^\d+$/;
$msgno = $f[0];
$fn = $f[1];

$ref = DXMsg::get($f[0]);
return (1, $self->msg('read2', $msgno)) unless $ref;
if (-e $fn) {
	my $m = $self->msg('e16', $fn);
	Log('msg', $self->call . " tried to export $m");
	dbg($m) if isdbg('msg');
	return (1, $m);
}

return (1, $self->msg('e16', $fn)) if -e $fn;

my $s = $ref->private ? "SP " : "SB " ;
push @body, $s  .  $ref->to . " < " . $ref->from;
push @body, $ref->subject;
push @body, $ref->read_msg_body;
push @body, "/EX";

my $fh = new IO::File ">$fn";
my $m;
if ($fh) {
	print $fh map { "$_\n" } @body;
	$fh->close;
    $m = $self->msg('export3', $msgno, $fn, $self->call);
} else {
	$m = $self->msg('export2', $msgno, $fn, $!, $self->call);
} 
Log('msg', $m);
dbg($m) if isdbg('msg');
push @out, $m;

return (1, @out);
