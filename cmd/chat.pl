#
# do a chat message
#
# this is my version of conferencing....
#
# Copyright (c) 2003 Dirk Koopman G1TLH
#
#

my ($self, $line) = @_;
#$DB::single = 1;

my @f = split /\s+/, $line, 2;
return (1, $self->msg('e5')) if $self->remotecmd || $self->inscript;
return (1, $self->msg('e34')) unless @f >= 1;
return (1, $self->msg('e28')) unless $self->isregistered;

my $target = uc $f[0];

return (1, $self->msg('e35', $target)) unless grep uc $_ eq $target, @{$self->user->group};

$f[1] ||= '';

my $from = $self->call;
my $text = $f[1] ;
my $t = ztime(time);
my $toflag = '*';
my @out;

# change ^ into : for transmission
$line =~ s/\^/:/og;

if ($text) {
	my @bad;
	if (@bad = BadWords::check($line)) {
		$self->badcount(($self->badcount||0) + @bad);
		LogDbg('DXCommand', "$self->{call} swore: $line (with words:" . join(',', @bad) . ")");
		Log('chat', $target, $from, "[to $from only] $line");
		return (1, "$target de $from <$t>: $line");
	}

	$self->send_chats($target, $text);
} else {
	my $ref = $self->talklist;
	if ($ref) {
		push @out, $self->msg('chattoomany', $target, $self->talklist->[0]);
	} else {
		$self->talklist([ $target ]);
		push @out, $self->msg('chatinst', $target);
		$self->state('chat');
	}
	Log('chat', $target, $from, "Started chat mode on $target");
	push @out, $self->chat_prompt;
}


return (1, @out);
