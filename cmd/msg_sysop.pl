#
#  msg_sysop.pl — Send message to sysop via Telegram and handle REGISTRO
#
#  Description:
#    Sends a user message to the sysop via Telegram and/or email.
#    If the subject contains "REGISTER"/"REGISTRO", the call/email/IP is stored
#    in pending_reg.txt and the user receives a confirmation email.
#
#  Usage:
#    msg_sysop <CALL> <SUBJECT> <EMAIL> <MESSAGE>
#    Example:
#      msg_sysop XX0ABC REGISTER xx0abc@example.com Requesting access
#      msg_sysop XX0XYZ HELP xx0xyz@example.com The sh/dx command fails
#      msg_sysop XX0XYZ RBN xx0xyz@example.com RBN filter is not activated
#
#  Installation:
#    Save as: /spider/local_cmd/msg_sysop.pl
#
#  Requirements:
#    - /spider/local/DXVars.pm with Telegram and email config
#    - /spider/local/Local.pm must be updated too.
#
#  Config:
#    $use_telegram = 1;    # Enable Telegram notifications
#    $use_email    = 1;    # Enable user email confirmation
#
#  Author  : Kin EA3CV (ea3cv@cronux.net)
#  Version : 20250413 v0.7
#

use strict;
use warnings;
use Local;
use File::Path qw(make_path);
use List::Util qw(first);
use Digest::SHA qw(sha1_hex);
use POSIX qw(strftime);

my $use_telegram = 1;
my $use_email    = 1;

# Editable confirmation email body (bilingual)
my $confirm_body = <<"EMAIL";
En breve recibira una respuesta.
Saludos.

You will receive a response shortly.
Regards,

$main::myname $main::myalias
EMAIL

my ($self, $line) = @_;

my @args = split /\s+/, $line;
unless (@args >= 4) {
    return (1,
        "Usage: msg_sysop <CALL> <SUBJECT> <EMAIL> <MESSAGE>",
        "Example:",
        "  msg_sysop XX0ABC REGISTER xx0abc\@example.com Requesting access"
    );
}

my ($call, $subject, $email, @message_parts) = @args;
my $message = join(' ', @message_parts);

my $real_call = $self->call // 'unknown';
my $conn = $self->conn;
my $ip = $conn->{peerhost} // 'unknown';

my @out;

if ($subject =~ /\b(register|registro)\b/i) {
    my $file = "/spider/local_data/pending_reg.txt";
    my $password = generate_password();
    my $now = strftime("%Y%m%d-%H%M%S", localtime);
    my $date = substr($now, 0, 8);  # para el límite diario por IP

    my $entry = join(',', $now, '00000000-000000', 'PENDING ', uc($call), $password, $ip, $email);

    my @lines;
    my $found = 0;
    my $ip_count = 0;

    eval {
        unless (-d "/spider/local_data") {
            make_path("/spider/local_data");
            push @out, "Directory /spider/local_data created.\n";
        }

        if (-e $file) {
            open my $rfh, '<', $file or die "Cannot read $file: $!";
            while (my $line = <$rfh>) {
                chomp $line;

                # Contar registros por IP en la fecha actual
                if ($line =~ /^(\d{8})-\d{6},.*?,.*?,.*?,.*?,$ip,/) {
                    $ip_count++ if $1 eq $date;
                }

                if ($line =~ /,$call,/i) {
                    push @lines, $entry;
                    $found = 1;
                } else {
                    push @lines, $line;
                }
            }
            close $rfh;
        }

        if ($ip_count >= 10) {
            push @out, "Request denied: Too many registrations from IP $ip today.";
            return (1, @out);
        }

        push @lines, $entry unless $found;

        open my $wfh, '>', $file or die "Cannot write $file: $!";
        print $wfh "$_\n" for @lines;
        close $wfh;
    };

    if ($@) {
        push @out, "Error writing $file: $@\n";
    }

    if ($use_email) {
        eval {
            Local::send_email($email, "Msg del sysop de / Msg from sysop of $main::mycall", $confirm_body);
        };
    }
}

# Telegram to sysop
if ($use_telegram) {
    my $sent_date = strftime("%d %B %Y %H:%M:%S", localtime);
    my $payload = <<"TELEGRAM";
📡 *Message from DXSpider command:*
*Date:* $sent_date
*Call:* $call
*Subject:* $subject
*Email:* $email
*Sent by:* $real_call
*IP:* $ip
$message
TELEGRAM

    eval {
        Local::telegram($payload);
    };
    push @out, "Warning: Telegram send failed: $@" if $@;
}

# Email internal sysop copy
if ($use_email) {
    my $sysop_body = <<"SYSMSG";
New message via msg_sysop command:

Node: $main::mycall
Call: $call
Subject: $subject
Email: $email
IP: $ip
Message: $message

SYSMSG

    eval {
        Local::send_email($main::email_from, "Msg received from $call ($subject) to $main::mycall", $sysop_body);
    };
}

push @out, "Message sent to sysop.";
push @out, " ";
push @out, "   Call: $call";
push @out, "Subject: $subject";
push @out, "  Email: $email";
push @out, "Message: $message\n";
push @out, " ";

return (1, @out);

sub generate_password {
    my @chars = ('A'..'Z', 'a'..'z', 0..9, qw/[] . - = % & $/);
    return join('', map { $chars[int rand @chars] } 1..8);
}
