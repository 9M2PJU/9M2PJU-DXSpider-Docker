#
# do an announce message 
#
# handles announce
#         announce full
#         announce sysop
#
# at the moment these keywords are fixed, but I dare say a file containing valid ones
# will appear
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#
# Modified 13Dec98 Iain Phillips G0RDI
#

my ($self, $line) = @_;
#$DB::single = 1;
my $addr = $self->hostname || '127.0.0.1';
Log('cmd', "$self->{call}|$addr|announce|$line");
my @f = split /\s+/, $line;
return (1, $self->msg('e5')) if $self->remotecmd || $self->inscript;
return (1, $self->msg('e9')) if !@f;
return (1, $self->msg('e28')) unless $self->isregistered;

my $sort = uc $f[0];
my $to = '*';
my $from = $self->call;
my $t = ztime(time);
my $tonode;
my $toflag = '*';
my $sysopflag;
my $via = 'LOCAL';

if ($sort eq "FULL") {
  $line =~ s/^$f[0]\s+//;    # remove it
  $via = $to = "*";
} elsif ($sort eq "SYSOP") {
  $line =~ s/^$f[0]\s+//;     # remove it
  $to = "SYSOP";
  $via = $sysopflag = '*';
} elsif ($sort eq "LOCAL") {
  $line =~ s/^$f[0]\s+//;     # remove it
}

# if this is a 'bad spotter' user then ignore it
my $nossid = $from;
my $drop = 0;
$nossid =~ s/-\d+$//;
if ($DXProt::badspotter->in($nossid)) {
	LogDbg('DXCommand', "bad spotter ($self->{call}) made announcement: $line");
	$drop++;
}

# have they sworn?
my @bad;
if (@bad = BadWords::check($line)) {
	$self->badcount(($self->badcount||0) + @bad);
	LogDbg('DXCommand', "$self->{call} swore: $line (with words:" . join(',', @bad) . ")");
	$drop++;
}

if ($drop) {
	Log('ann', $to, $from, "[to $from only] $line");
	$self->send("To $to de $from: $line");
	return (1, ());
}

#return (1, $self->msg('dup')) if $self->priv < 5 && AnnTalk::dup($from, $toflag, $line);
Log('ann', $to, $from, $line);
$main::me->normal(DXProt::pc93($to, $from, $via, $line));

#DXChannel::broadcast_list("To $to de $from ($t): $line\a", 'ann', undef, @locals);
#if ($to ne "LOCAL") {
#  my $pc = DXProt::pc12($from, $line, $tonode, $sysopflag, 0);
#  DXChannel::broadcast_nodes($pc);
#}

return (1, ());
