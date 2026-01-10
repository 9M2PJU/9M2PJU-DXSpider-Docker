#
#  deny_register.pl — Deny a pending registration in DXSpider
#
#  Description:
#    Marks a pending registration as DENIED in pending_reg.txt.
#    Notifies the user via email and the sysop via Telegram (optional).
#
#  Usage:
#    From DXSpider shell:
#      deny_register <CALLSIGN>
#
#  Requirements:
#    - Entry in /spider/local_data/pending_reg.txt
#
#  Author  : Kin EA3CV (ea3cv@cronux.net)
#  Version : 20250412 v0.3
#

use strict;
use warnings;
use Local;
use POSIX qw(strftime);

my $use_telegram = 1;
my $use_email    = 1;

# Mensaje para el usuario rechazado (ES + EN)
my $msg_es = <<"ES";
Se ha denegado su solicitud de registro.

Si cree que esto es un error, puede contactar con el administrador.
Gracias.
ES

my $msg_en = <<"EN";
Your registration request has been denied.

If you believe this is a mistake, please contact the administrator.
Thank you.
EN

my ($self, $line) = @_;

unless ($line =~ /^\s*(\S+)/) {
    return (1, "Usage: deny_register <CALLSIGN>");
}

my $target_call = uc($1);
my $file        = "/spider/local_data/pending_reg.txt";
my $tempfile    = "/spider/local_data/pending_reg.tmp";
my $now         = strftime("%Y%m%d-%H%M%S", localtime);

open(my $in,  '<', $file)     or return (1, "❌ Cannot open $file: $!");
open(my $out, '>', $tempfile) or return (1, "❌ Cannot create $tempfile: $!");

my $found;
while (my $line = <$in>) {
    chomp $line;
    my @f = split(/,/, $line, 7);
    if (uc($f[3]) eq $target_call) {
        $found = {
            call  => $f[3],
            pass  => $f[4],
            ip    => $f[5],
            email => $f[6],
        };
        $f[1] = $now;
        $f[2] = 'DENIED  ';
        $line = join(',', @f);
    }
    print $out "$line\n";
}

close($in);
close($out);
rename $tempfile, $file;

unless ($found) {
    return (1, "❌ No pending registration found for $target_call.");
}

if ($use_email) {
    my $body = $msg_es . "\n\n" . $msg_en . "\n\n$main::myname $main::myalias";

    Local::send_email(
        $found->{email},
        "Denegada su solicitud de registro / Registration denied $found->{call} at $main::mycall",
        $body
    );
}

if ($use_telegram) {
    Local::telegram("❌ DENIED registration of $found->{call} from $found->{ip}");
}

return (1,
    "   Registration denied for $found->{call}",
    "   Email: $found->{email}",
    "   IP:    $found->{ip}"
);
