# the help subsystem
#
# apropos - this does a grep on the command file and returns the commands
# that contain the string searched for
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @out;

my $lang = $self->lang;
$lang = 'en' if !$lang;

#print "$line\n";
my $in;
$line = 'help' unless $line;
$line =~ s/\ball\b/.*/;
$line =~ s/\W//g;   # remove dubious characters
print "$line\n";

my ($priv, $cmd, $param, $desc);
my %cmd;

my $defh = new IO::File;
unless ($defh->open("$main::localcmd/Commands_en.hlp")) {
	unless($defh->open("$main::cmd/Commands_en.hlp")) {
		return (1, $self->msg('helpe1'));
	}
}

my $h;
if ($lang ne 'en') {
	$h = new IO::File;
	unless ($h->open("$main::localcmd/Commands_$lang.hlp")) {
		unless($h->open("$main::cmd/Commands_$lang.hlp")) {
			undef $h;
		}
	}
}

# do english help
foreach $in (<$defh>) {
	next if $in =~ /^\#/;
	chomp $in;
	$in =~ s/\r$//;
	if ($in =~ /^===/) {
#		print "$in\n";
		($priv, $cmd, $param, $desc) = $in =~ m{^===\s+(\d)\^(\S+)(\s+[^\^]+)?\^(.*)};
		$param ||= '';
		$desc ||= '';
		next if $priv > $self->priv;             # ignore subcommands that are of no concern
		next unless $in =~ /$line/i;
		next if $cmd =~ /-$/o;
		push @{$cmd{$cmd}->{en}}, "$cmd$param $desc";
		next;
	}
}
$defh->close;

# override with any not english help
if ($h) {
	my $include;
	foreach $in (<$h>) {
		next if $in =~ /^\#/;
		chomp $in;
		$in =~ s/\r$//;
		if ($in =~ /^===/) {
#			print "$in\n";
			($priv, $cmd, $param, $desc) = $in =~ m{^===\s+(\d)\^(\S+)(\s+[^\^]+)?\^(.*)};
			$param ||= '';
		    $desc ||= '';
			next if $priv > $self->priv;             # ignore subcommands that are of no concern
			next unless $in =~ /$line/i;
			next if $cmd =~ /-$/o;
			push @{$cmd{$cmd}->{$lang}}, "$cmd$param $desc";
			next;
		}
	}
	$h->close;
}

foreach my $k (sort keys %cmd) {
	my $v;
	if ($v = $cmd{$k}->{$lang}) {
		push @out, @$v; 
	} elsif	($v = $cmd{$k}->{en}) {
		push @out, @$v;
	}
}

push @out, $self->msg('helpe2', $line) if @out == 0;

return (1, @out);
