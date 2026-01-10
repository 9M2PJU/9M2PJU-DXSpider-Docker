#
#  musers.pl — List connected DXSpider users
#
#  Description:
#    This script lists all connected users with flags for
#    registration and password, plus connection type and uptime.
#
#  Usage:
#    From DXSpider shell: musers   (or create alias 'mu')
#
#  Installation:
#    Save as: /spider/local_cmd/musers.pl
#
#  Author   : Kin EA3CV (ea3cv@cronux.net)
#  Version  : 20250608 v1.7
#

use strict;
use warnings;

my $self = shift;
return 1 unless $self->priv >= 5;

my $tnow = time();
my @out = (
    " ",
    " List of Connected Users:",
    " ",
    " Callsign  R P  Type       Connection Time",
    " --------  - -  ---------  ---------------"
);

my ($total, $registered, $with_passwd) = (0, 0, 0);

foreach my $dxchan (sort { $a->call cmp $b->call } DXChannel::get_all_users) {
    my $call = $dxchan->call;
    my $isreg = reg($call) ? "R" : " ";
    my $ispass = pass($call) ? "P" : " ";
    my $sort = "    ";

    $sort = "LOCL" if $dxchan->conn->isa('IntMsg');
    $sort = "WEB " if $dxchan->is_web;
    $sort = "EXT " if $dxchan->conn->isa('ExtMsg');

    my $delta = $tnow - $dxchan->startt;
    my $time_on = sprintf("%3d d%3d h %3d m",
        int($delta / (24 * 60 * 60)),
        int(($delta / (60 * 60)) % 24),
        int(($delta / 60) % 60)
    );

    push @out, sprintf(" %-9s $isreg $ispass  USER $sort $time_on", $call);

    $total++;
    $registered++ if $isreg eq "R";
    $with_passwd++ if $ispass eq "P";
}

push @out, " ", sprintf(
    "Total:%5d  Register:%5d  Password:%5d",
    $total, $registered, $with_passwd
), " ";

return (1, @out);

sub reg {
    my $call = shift;
    my $ref = DXUser::get_current(uc $call);
    return defined $ref && defined $ref->{registered} && $ref->{registered} eq "1";
}

sub pass {
    my $call = shift;
    my $ref = DXUser::get_current(uc $call);
    return defined $ref && defined $ref->{passwd};
}
