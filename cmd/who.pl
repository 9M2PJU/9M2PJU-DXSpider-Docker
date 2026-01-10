#
# who.pl — Complete list of connected stations
#
# Description:
#   Lists all currently connected stations with type, registration,
#   password status, connection type, start time, RTT and IP.
#
# Usage:
#   From DXSpider shell: who
#
# Installation:
#   Copy to /spider/local_cmd/who.pl
#
# Author   : Dirk Koopman G1TLH
#
# Modified : Kin EA3CV <ea3cv@cronux.net>
# Version  : 20250406 v0.3
#

use strict;
use warnings;

my $self = shift;
return 1 unless $self->priv >= 0;

my $tnow = time();
my @out = (
    " ",
    " List of All Connected Stations:",
    " ",
    " Callsign   R P  Type         Started           Name        RTT   IP",
    " --------   - -  ---------    ----------------  ----------  ----  --------------"
);

foreach my $dxchan (sort { $a->call cmp $b->call } DXChannel::get_all) {
    my $call   = $dxchan->call();
    my $t      = cldatetime($dxchan->startt);
    my $type   = $dxchan->is_node ? "NODE" : "USER";
    my $sort   = "     ";

    $sort = "DXSP" if $dxchan->is_spider;
    $sort = "CCCL" if $dxchan->is_ccluster;
    $sort = "CLX " if $dxchan->is_clx;
    $sort = "DXNT" if $dxchan->is_dxnet;
    $sort = "AR-C" if $dxchan->is_arcluster;
    $sort = "AK1A" if $dxchan->is_ak1a;
    $sort = "RBN " if $dxchan->is_rbn;
    $sort = "LOCL" if !$dxchan->is_node && $dxchan->conn && $dxchan->conn->isa('IntMsg');
    $sort = "WEB " if !$dxchan->is_node && $dxchan->is_web;
    $sort = "EXT " if !$dxchan->is_node && $dxchan->conn && $dxchan->conn->isa('ExtMsg');

    my $name   = $dxchan->user->name || "";
    my $ping   = $dxchan->is_node && $dxchan != $main::me ? sprintf("%5.2f", $dxchan->pingave) : "     ";
    my $ip     = "";
    my $conn   = $dxchan->conn;

    $ip = $dxchan->hostname if $conn;
    $ip = "AGW Port ($conn->{agwport})" if $conn && exists $conn->{agwport};

    my $isreg  = $dxchan->isregistered ? "R" : " ";
    my $ispass = has_pass($call)       ? "P" : " ";

    push @out, sprintf(" %-9s  %s %s  %-5s %-4s  %-16s  %-10s  %-4s  %s",
        $call, $isreg, $ispass, $type, $sort, $t, $name, $ping, $ip);
}

push @out, " ";

return (1, @out);

sub has_pass {
    my $call = shift;
    my $ref = DXUser::get_current(uc $call);
    return defined $ref && defined $ref->{passwd};
}
