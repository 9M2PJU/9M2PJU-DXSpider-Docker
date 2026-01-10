#
#  Local.pm — Send DXSpider traffic to MQTT in JSON format
#
#  Description:
#    Sends selected DXSpider traffic (SPOTS, ANN, WWV, WCY, RBN, etc.)
#    to a local MQTT broker in JSON format.
#    Also handles Telegram alerts and optional email notifications.
#
#  Usage:
#    Loaded automatically by DXSpider. No direct invocation required.
#
#  Installation:
#    Save as: /spider/local/Local.pm
#
#  Requirements:
#    Modules:
#      cpanm Net::MQTT::Simple
#      sudo apt install libnet-smtp-perl libnet-smtp-ssl-perl libauthen-sasl-perl
#      or:
#      sudo cpanm Net::MQTT::Simple Net::SMTP::SSL Authen::SASL
#
#  Config:
#    Telegram and email parameters must be set in: /spider/local/DXVars.pm
#
#  Notes:
#    Changes in this module require restarting the node.
#    Based on original development by Dirk Koopman G1TLH.
#
#  Author  : Kin EA3CV (ea3cv@cronux.net)
#  Version : 20250413 v7.4
#

package Local;

use DXVars;
use DXDebug;
use DXUtil;
use JSON;
use DXLog;
use 5.10.1;
use Net::MQTT::Simple;
use Net::SMTP;
use Net::SMTP::SSL;
use Authen::SASL qw(Perl);
use strict;

# declare any global variables you use in here
use vars qw{$mqtt $json};

# called at initialisation time
sub init {
    $mqtt = Net::MQTT::Simple->new("localhost:1883");
}

# called once every second
#sub process
#{
#
#}

# called just before the ending of the program
#sub finish
#{
#
#}

sub pcprot {
    my ($self, $pcno, $line, @field) = @_;

    SWITCH: {
        if ($pcno == 11 || $pcno == 26 || $pcno == 61) { # dx spot
            my %mqtt_spot = ('SPOTS' => $line);
            $json = JSON->new->canonical(1)->encode(\%mqtt_spot);
            $mqtt->publish("spider/raw/nodo-6", $json);
            return 0;
            last SWITCH;
        }

        if ($pcno == 12 || $pcno == 93) { # announces
            my %mqtt_spot = ('ANN' => $line);
            $json = JSON->new->canonical(1)->encode(\%mqtt_spot);
#           $mqtt->publish("spider/raw/nodo-6", $json);
##          return 0;
            last SWITCH;
        }

        if ($pcno == 23 || $pcno == 27) { # WWV info
            my %mqtt_spot = ('WWV' => $line);
            $json = JSON->new->canonical(1)->encode(\%mqtt_spot);
#           $mqtt->publish("spider/raw/nodo-6", $json);
##          return 0;
            last SWITCH;
        }

        if ($pcno == 73) { # WCY info
            my %mqtt_spot = ('WCY' => $line);
            $json = JSON->new->canonical(1)->encode(\%mqtt_spot);
#           $mqtt->publish("spider/raw/nodo-6", $json);
##          return 0;
            last SWITCH;
        }

        # Muchos otros if ($pcno == ...) comentados
    }

    return 0;
}

sub rbn {
    my ($self, $origin, $qrg, $call, $mode, $s, $utz, $respot) = @_;

    my $l_rbn = "$self, $origin, $qrg, $call, $mode, $s, $utz, $respot";
    my %mqtt_rbn = ('RBN' => $l_rbn);
    $json = JSON->new->canonical(1)->encode(\%mqtt_rbn);
#   $mqtt->publish("spider/raw/nodo-6", $json);
    return 0;
}

sub rbn_quality {
    my ($self, $line) = @_;

    my %mqtt_rbn = ('RBN' => $line);
    $json = JSON->new->canonical(1)->encode(\%mqtt_rbn);
#   $mqtt->publish("spider/raw/nodo-6", $json);
    return 0;
}

sub log_msg {
    my ($self, $t, $line) = @_;

    my $node = $main::mycall;
    my @fields = split(/\^/, $line);

    $fields[2] =~ m/(\w+||\w+\-\d+)\s(\w+)/ if defined $fields[2];
    my $texto = "";

    if ($fields[1] eq "DXCommand") {
        if ($2 eq "connected") {
            $texto = "*$node*   ✅  *$1* Connect \(*U*\)";
            telegram($texto);
        } elsif ($2 eq "disconnected") {
            $texto = "*$node*   ❌  *$1* Disconnect \(*U*\)";
            telegram($texto);
        }
    } elsif ($fields[1] eq "DXProt") {
        if ($2 eq "connected") {
            $texto = "*$node*   ✅  *$1* Connect \(*N*\)";
            telegram($texto);
        } elsif ($2 eq "Disconnected") {
            $texto = "*$node*   ❌  *$1* Disconnect \(*N*\)";
            telegram($texto);
        }
    } elsif ($fields[1] eq "RBN") {
        if ($1 eq "RBN" and $6 eq "disconnecting") {
            $texto = "*$node*   ❌  *$1* Disconnect \(*U*\)";
            telegram($texto);
        }
    } elsif ($fields[1] eq "" and $2 eq "has too many connections") {
        $texto = "*$node*   ❎  *$1* Many connections";
        telegram($texto);
    } elsif ($fields[1] eq "cluster") {
        if ($fields[2] =~ /started/) {
            $texto = "*$node*   ⬆️  Cluster *UP*";
            telegram($texto);
        } elsif ($fields[2] =~ /ended/) {
            $texto = "*$node*   ⬇️  Cluster *DOWN*";
            telegram($texto);
        }
    } elsif ($fields[1] =~ /Message no/) {
        my @text = split(/ /, $fields[1]);
        if ($text[11] eq $main::myalias) {
            my $file = sprintf('m%06d', $text[6]);
            my $msg_file = "/spider/msg/" . $file;
            my $msg = do { local(@ARGV, $/) = $msg_file; <> };

            my @head = split(/\^/, $msg);
            my $num = "Msg: *$text[6]*\n";
            my $from = "From: *$head[2]*\n";
            my $subj = "Subj: *$head[5]*";
            $msg =~ s/^===.+?===//s;
            $msg = "*$main::mycall*   🆕  $num" . $from . $subj . $msg;
            telegram($msg);
        }
    }

    return 0;
}

sub telegram {
    my $payload = shift;

    my $url = "https://api.telegram.org/bot$main::token/sendMessage";
    `curl -s -X POST $url -d chat_id=$main::id -d text="$payload\n" -d parse_mode="Markdown"`;
}

sub send_email {
    my ($to, $subject, $body) = @_;

    return unless $main::email_enable;

#    LogDbg('mail', "Preparing to send email to $to");
#    LogDbg('mail', "SMTP: $main::email_smtp");
#    LogDbg('mail', "Port: $main::email_port");
#    LogDbg('mail', "From: $main::email_from");
#    LogDbg('mail', "User: $main::email_user");

    my $smtp;

    if ($main::email_port == 465) {
#        LogDbg('mail', "Connecting via SSL to $main::email_smtp :$main::email_port");
        $smtp = Net::SMTP::SSL->new(
            $main::email_smtp,
            Port    => $main::email_port,
            Hello   => 'localhost',
            Timeout => 30,
            Debug   => 1,
        );
    } else {
#        LogDbg('mail', "Connecting via STARTTLS to $main::email_smtp :$main::email_port");
        $smtp = Net::SMTP->new(
            $main::email_smtp,
            Port    => $main::email_port,
            Hello   => 'localhost',
            Timeout => 30,
            Debug   => 1,
        );

        unless ($smtp && $smtp->starttls) {
#            LogDbg('mail', "Error starting STARTTLS");
            return;
        }
    }

#    unless ($smtp) {
#        LogDbg('mail', "Could not connect to $main::email_smtp on port $main::email_port");
#        return;
#    }

    unless ($smtp->auth($main::email_user, $main::email_pass)) {
#        LogDbg('mail', "SMTP authentication failed for $main::email_user");
        return;
    }

    unless ($smtp->mail($main::email_from)) {
#        LogDbg('mail', "MAIL FROM failed for $main::email_from");
        return;
    }

    unless ($smtp->to($to)) {
#        LogDbg('mail', "RCPT TO failed for $to");
        return;
    }

    $smtp->data();
    $smtp->datasend("From: $main::email_from\n");
    $smtp->datasend("To: $to\n");
    $smtp->datasend("Subject: $subject\n");
    $smtp->datasend("Content-Type: text/plain; charset=utf-8\n\n");
    $smtp->datasend("$body\n");

    my $ok = $smtp->dataend();

    if ($ok) {
        LogDbg('mail', "Email successfully sent to $to");
    } else {
        LogDbg('mail', "Error sending SMTP data to $to");
    }

    $smtp->quit;
}

1;
__END__
