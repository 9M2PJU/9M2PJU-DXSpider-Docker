#!/usr/bin/perl

#
# Total Nodes/Users sent to the Telegram bot 
#
# Copy it in: /spider/local_cmd/total.pl
#
# Include the following line in the crontab:
# 0 * * * * run_cmd("total")
#
# Created by Kin EA3CV, ea3cv@cronux.net
#
# 20230203 v0.1
#

use strict;
use warnings;
use 5.10.1;

my ($self, $server) = @_;

return (1) unless $self->priv >= 5;

my $all_users = scalar DXChannel::get_all_users();
my $all_nodes = scalar DXChannel::get_all_nodes();

my $load = "*$main::mycall*   ➡️  Nodes: *$all_nodes*   Users: *$all_users*";
if (defined &Local::telegram) {
	my $r;
	eval { $r = Local::telegram($load); };
	return if $r;
}

return (1)
