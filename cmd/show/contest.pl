# contest.pl - contest calendar from www.sk3bg.se/contest
# used with 1 argument: sh/contest <yearandmonth>
# e g sh/contest 2002sep
# Tommy Johansson (SM3OSM) 2002-07-23
#
# New version use AsyncMsg (c) Dirk Koopman G1TLH
#

sub handle
{
	my ($self, $line) = @_;

	return (1, $self->msg('e24')) unless $Internet::allow;

	my @out;

	#$DB::single = 1;


	# trying to make the syntax abit more user friendly...
	# and yes, I have been here and it *is* all my fault (dirk)
	$line = lc $line;
	my ($m,$y);
	($y) = $line =~ /(\d+)/;
	($m) = $line =~ /([a-z]{3})/;

	unless ($y) {
		($y) = (gmtime)[5];
		$y += 1900;
	}
	unless ($m) {
		($m) = (gmtime)[4];
		$m = lc $DXUtil::month[$m];
	}
	$y += 2000 if $y <= 50;
	$y += 1900 if $y > 50 && $y <= 99;
	$m = substr $m, 0, 3 if length $m > 3;
	$m = 'oct' if $m eq 'okt';
	$m = 'may' if $m eq 'mai' || $m eq 'maj';
	my $mon = "$y$m";

	dbg("sh/contest: month=$mon") if isdbg('contest');

	my $filename = "c" . $mon . ".txt";
	my $host = $Internet::contest_host || 'www.sk3bg.se';
	my $port = 80;

	dbg("sh/contest: host=$host:$port") if isdbg('contest');

	my $url = $Internet::contest_url || "/contest/text";
	$url .= "/$filename";

	dbg("sh/contest: url=$url") if isdbg("contest");

	my $r = AsyncMsg->get($self->call, $host, $port, $url, prefix=>'ctst> ');
	if ($r) {
		push @out, $self->msg('m21', "show/contest");
	}
	else {
		push @out, $self->msg('e18','sk3bg.se');
	}

	return (1, @out);
}
