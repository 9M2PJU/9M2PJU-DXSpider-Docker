# 
# the help subsystem
#
# It is a very simple system in that you type in 'help <cmd>' and it
# looks for a file called command.hlp in either the local_cmd directory
# or the cmd directory (in that order). 
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @out;

# this is naff but it will work for now
my $lang = $self->lang;
$lang = 'en' if !$lang;

# each help file contains lines that looks like:-
#
# === 0^*^Description
# text
# text
#
# === 0^help^Description
# text
# text
# text 
#
# The fields are:- privilege level, full command name, short description
#

#$DB::single = 1;


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

my $in;

#$line =~ s/[^\w\/]//g;
#$line =~ s/\//\.\*\//g;

$line =~ s{[^\w/]}{}g;
$line =~ s{/}{.*/}g;
$line =~ s/^\s+//g;
$line =~ s/[\s\r]+$//g;
$line = "help" if $line =~ /^\s*$/;

# sort out aliases
my $alias = CmdAlias::get_hlp($line);
$line = $alias if $alias;

# non english help (if available)
if ($h) {
	my $state = 0;
	foreach $in (<$h>) {
		next if $in =~ /^\#/;
		chomp $in;
		$in =~ s/\r$//;
		if ($in =~ /^===/) {
			last if $state == 2;           # come out on next command
			$in =~ s/=== //;
			my ($priv, $cmd, $desc) = split /\^/, $in;
			next if $priv > $self->priv;             # ignore subcommands that are of no concern
			next unless $cmd =~ /^$line/i;
			push @out, "$cmd $desc" unless $cmd =~ /-$/o;
			$state = 1;
			next;
		}
		if ($state > 0) {
			push @out, " $in";
			$state = 2;
		}
	}
	$h->close;

	# return if some help was given, otherwise continue to english help
	return (1, @out) if @out && $state == 2;
}

# standard 'english' help
my $state = 0;
foreach $in (<$defh>) {
	next if $in =~ /^\#/;
	chomp $in;
	if ($in =~ /^===/) {
		last if $state == 2;           # come out on next command
		$in =~ s/=== //;
		my ($priv, $cmd, $desc) = split /\^/, $in;
		next if $priv > $self->priv;             # ignore subcommands that are of no concern
		next unless $cmd =~ /^$line/i;
		push @out, "$cmd $desc" unless $cmd =~ /-$/o;
		$state = 1;
		next;
	}
	if ($state > 0) {
		push @out, " $in";
		$state = 2;
	}
}
$defh->close;

push @out, $self->msg('helpe2', $line) if @out == 0;
return (1, @out);

