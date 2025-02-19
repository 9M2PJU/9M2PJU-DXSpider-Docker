#
# do an wx message, this is identical to the announce except that it does WX
# instead
#
# handles wx
#         wx full
#         wx sysop
#
# at the moment these keywords are fixed, but I dare say a file containing valid ones
# will appear
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $sort = uc $f[0];
my $to;
my $from = $self->call;
my $t = ztime(time);
my $tonode;
my $via;
return (1, $self->msg('e5')) if $self->remotecmd || $self->inscript;
return (1, $self->msg('e28')) unless $self->isregistered;

if ($sort eq "FULL") {
  $line =~ s/^$f[0]\s+//;    # remove it
} else {
  $via = "LOCAL";
}
$to = 'WX';

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
	$self->send("WX de $from: $line");
	return (1, ());
}

Log('ann', $via ? $via : '*', $from, $line);
$main::me->normal(DXProt::pc93($to, $from, $via, $line));

#DXChannel::broadcast_list("WX de $from <$t>: $line", 'wx', undef, @locals);
#if ($to ne "LOCAL") {
#  $line =~ s/\^//og;    # remove ^ characters!
#  my $pc = DXProt::pc12($from, $line, $tonode, $sysopflag, 1);
#  DXChannel::broadcast_nodes($pc, $main::me);
#}

return (1, ());
