#
#  unset/badip - Remove IPs from the badip file
#
#  Description:
#    This command allows a sysop to remove one or more IP addresses
#    from the badip list used by DXCIDR. The list is maintained in
#    files such as 'badip.local', 'badip.eu', etc., and used to block
#    undesired connections.
#
#  Usage:
#    unset/badip [suffix] ip [ip2 ip3 ...]
#
#  Examples:
#    unset/badip 192.168.1.10
#    unset/badip eu 192.168.1.10 192.168.1.20
#
#  Notes:
#    - The default suffix is 'local' if none is specified.
#    - Only IP addresses present in the list will be removed.
#    - The badip file is rewritten and the CIDR database reloaded.
#
#  Installation:
#    Place this script in: /spider/local_cmd/unset
#
#  Author:   Kin EA3CV <ea3cv@cronux.net>
#
#  20250702 v1.0  to support MySQL backend
#

use strict;
use warnings;
use DXCIDR;
use DXVars;
use DBI;

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->remotecmd;
return (1, $self->msg('e5')) if $self->priv < 6;
return (1, q{Please install Net::CIDR::Lite or libnet-cidr-lite-perl to use this command}) unless $DXCIDR::active;

my @out;
my @in = split /\s+/, $line;
my $suffix = 'local';

if ($in[0] =~ /^[_\d\w]+$/) {
    $suffix = shift @in;
}

return (1, "unset/badip: need [suffix (def: local)] IP(s)") unless @in;

my %to_remove = map { $_ => 1 } grep { is_ipaddr($_) } @in;
my @removed;

# Detect backend
my $use_mysql = defined $main::db_backend && $main::db_backend eq 'mysql';

if ($use_mysql) {
    # MySQL backend
    my $dbh = DBI->connect(
        "DBI:mysql:database=$main::mysql_db;host=$main::mysql_host",
        $main::mysql_user,
        $main::mysql_pass,
        { RaiseError => 1, AutoCommit => 1, mysql_enable_utf8mb4 => 1 }
    );

    my $table = $main::mysql_badips || 'badips';
    my $sth = $dbh->prepare("DELETE FROM $table WHERE ip = ? AND suffix = ?");

    foreach my $ip (keys %to_remove) {
        my $cidr = ($ip =~ /:/) ? "$ip/128" : "$ip/32";
        my $count = $sth->execute($cidr, $suffix);
        push @removed, $ip if $count;
    }

    $dbh->disconnect;
} else {
    # File-based backend
    my $fn = DXCIDR::_fn() . ".$suffix";

    unless (-e $fn) {
        return (1, "unset/badip: file $fn does not exist.");
    }

    my @lines;
    if (open my $fh, '<', $fn) {
        @lines = <$fh>;
        close $fh;
    } else {
        return (1, "unset/badip: cannot read $fn: $!");
    }

    my @kept;
    foreach my $line (@lines) {
        chomp $line;
        next unless $line =~ /[\.:]/;
        if ($to_remove{$line}) {
            push @removed, $line;
        } else {
            push @kept, $line;
        }
    }

    if (open my $fh, '>', $fn) {
        print $fh "$_\n" for @kept;
        close $fh;
    } else {
        return (1, "unset/badip: cannot write to $fn: $!");
    }
}

# Reload the updated list
DXCIDR::reload();

if (@removed) {
    push @out, "unset/badip: removed ".scalar(@removed)." IP(s) from badip.$suffix: @removed";
} else {
    push @out, "unset/badip: no matching IPs found in badip.$suffix";
}

return (1, @out);

