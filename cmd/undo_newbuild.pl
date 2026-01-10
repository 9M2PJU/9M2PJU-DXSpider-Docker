#!/usr/bin/perl

#
# Revert to the version before the update.
# Mojo branch only
#
# Kin EA3CV, ea3cv@cronux.net
#
# 20230206 v0.0
#

use 5.10.1;
use DXDebug;
use strict;
use warnings;

my $self = shift;

return (1) unless $self->priv >= 9;

system('cd /spider');
system('git reset HEAD~1');
DXCron::run_cmd('shut');

my @out;

my $res = "The last update has been undone";
dbg('DXCron::spawn: $res') if isdbg('cron');
push @out, $res;
DXCron::run_cmd('shut');
my $msg = "*$main::mycall*   🔄  *UNDONE* last build";

if (defined &Local::telegram) {
	my $r;
	eval { $r = Local::telegram($msg); };
	return if $r;
}

return (1, @out)
