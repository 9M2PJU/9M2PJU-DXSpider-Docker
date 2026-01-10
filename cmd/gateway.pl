#!/usr/bin/perl

#
#  gateway.pl — Lightweight DXSpider node to inject PC92 messages from MQTT or FIFO
#
#  Description:
#    This script acts as a minimal DXSpider node. It connects to a full DXSpider
#    node via Telnet and sends PC92 messages (A/D/C/K) based on real-time events
#    received via MQTT or a named FIFO pipe.
#
#    It handles authentication, periodic PC92C, reports,
#    connection timeouts, and DXSpider protocol formatting.
#
#    After session initialization, the script filters incoming Telnet traffic and
#    only logs received PC51 messages (RX).
#
#    PC92A is sent once when a user connects, PC92D after inactivity,
#    PC92C is a summary sent periodically, and PC92K is a keepalive/status.
#
#  Usage:
#    Run the script as a background process or systemd service.
#
#  Installation:
#    Save as: /spider/local_cmd/gateway.pl
#    Configure your DXSpider node with:
#      set/spider <node>
#      set/register <node>
#      set/password <node> <password>
#
#  Requirements:
#    - Perl modules:
#        AnyEvent
#        IO::Socket::INET
#        IO::Handle
#        Time::HiRes
#        LWP::Simple
#        AnyEvent::Handle
#        AnyEvent::Socket
#        AnyEvent::MQTT
#        JSON
#
#  Input modes:
#    $mode = 'mqtt';   # Options: 'mqtt', 'fifo'
#
#    MQTT:
#      Payload JSON format:
#        { "call": "EA3XYZ", "ip": "1.2.3.4", "ts": 1713456789, "svc": "1", "ident": 1 }
#
#    FIFO:
#      Path: /tmp/kin_fifo
#      Input:
#        CONN,<CALL>,<IP>     triggers Add users
#        DESC,<CALL>          triggers Deleted users
#
#  Config:
#    $mode              = 'mqtt';         # Choose between 'mqtt' or 'fifo'
#    $fifo_path         = '/tmp/kin_fifo'
#    $timeout_conn      = 300;            # Inactivity timeout in seconds
#    $pc92c_interval    = 14400;          # Interval for PC92C summary (seconds)
#    $pc92k_interval    = 3600;           # Interval for PC92K keepalive (seconds)
#
#  Author  : Kin EA3CV (ea3cv@cronux.net)
#  Version : 20250530 v1.5
#
#  License : This software is released under the GNU General Public License v3.0 (GPLv3)
#

use strict;
use warnings;
use AnyEvent;
use IO::Socket::INET;
use IO::Handle;
use Time::HiRes qw/gettimeofday/;
use LWP::Simple;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::MQTT;
use JSON;

my $host       = 'localhost';
my $port       = 7300;
my $password   = 'xxxxxxx';
my $version    = 'kin_node:0.3';
my $mi_nodo    = 'XX0XXX-9';
my $username   = $mi_nodo;
my $mqtt_host  = '192.168.1.1';
my $mqtt_port  = 1883;
my $mqtt_topic = 'api/heartbeat/socio';
my $mode       = 'mqtt'; # 'mqtt' or 'fifo'
my $fifo_path  = '/tmp/kin_fifo';

my $pc92k_interval = 3600;   # 1 hour interval
my $pc92c_interval = 14400;  # 4 hour interval
my $timeout_conn   = 300;    # Timeout for disconnection due to inactivity
my $filter_rx_only_specific_pc = 0;

my $sock;
my $buffer = '';
my $state  = 'await_login';
my $mi_ip  = get_public_ip();
my $login_timeout_watcher;
my $remote_node = '';
my $cv = AnyEvent->condvar;
my %active_users;
my ($fifo_watcher, $mqtt, $telnet_watcher, $periodic_pc92_timer);

my $last_pc92c_time = 0;
my $last_pc92k_time = 0;

connect_telnet();

my $heartbeat = AnyEvent->timer(
    interval => 5,
    cb => sub {
        # print_log('**', "Heartbeat: alive, state = $state");
    }
);

$cv->recv;

sub connect_telnet {
    $sock = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        Timeout  => 10
    ) or return print_log('**', "Connection to $host:$port failed");

    $sock->autoflush(1);
    print_log('**', "Connected to $host:$port");
    start_login_timeout();

    $telnet_watcher = AnyEvent->io(
        fh   => $sock,
        poll => 'r',
        cb   => sub {
            # print_log('**', "Telnet watcher activated (callback)");

            my $bytes = sysread($sock, my $chunk, 4096);
            # print_log('**', "sysread: $bytes bytes read");
            # print_log('**', "chunk: [$chunk]") if defined $chunk && $chunk ne '';

            if (!$bytes) {
                print_log('**', "Disconnected");
                undef $telnet_watcher;
                reconnect_later();
                return;
            }

            $buffer .= $chunk;
            $buffer =~ s/\r\n/\n/g;
            $buffer =~ s/\r/\n/g;

            if ($state eq 'await_login' && index($buffer, 'login:') != -1) {
                print_log('RX', 'login:');
                send_telnet($username);
                $state = 'await_password';
                $buffer = '';
                return;
            }
            if ($state eq 'await_password' && index($buffer, 'password:') != -1) {
                print_log('RX', 'password:');
                send_telnet($password);
                $state = 'await_pc18';
                cancel_login_timeout();
                $buffer = '';
                return;
            }

            while ($buffer =~ s/^(.*?\n)//) {
                my $line = $1;
                $line =~ s/\n$//;
                handle_line($line);
            }
        }
    );
}

sub handle_line {
    my ($line) = @_;

    if ($state eq 'await_pc18' && $line =~ /^PC18/) {
        print_log('RX', $line);
        send_pc92a();
        send_pc92k();
        send_telnet("PC20");
        $state = 'await_pc92_pc22';
        return;
    }

    if ($state eq 'await_pc92_pc22') {
        if ($line =~ /^PC92\^([A-Z0-9\-]+)\^.*\^A\^/) {
            $remote_node = $1 unless $remote_node;
            print_log('RX', $line);
        } elsif ($line =~ /^PC92\^.*\^K\^/) {
            print_log('RX', $line);
        } elsif ($line =~ /^PC22\^/) {
            print_log('RX', $line);
            print_log('**', "Session initialized with node $remote_node");
            $filter_rx_only_specific_pc = 1;
            $state = 'ready';
            $last_pc92c_time = time;
            $last_pc92k_time = time;

            $periodic_pc92_timer = AnyEvent->timer(
                after    => 5,
                interval => 60,
                cb       => \&check_pc92_timers
            );

            if ($mode eq 'mqtt' && !$mqtt) {
                start_mqtt();
            } elsif ($mode eq 'fifo' && !$fifo_watcher) {
                start_fifo();
            }
            return;
        }
        return;
    }

    if ($state eq 'ready') {
        print_log('RX', $line) unless $line =~ /^PC22\^/;

        if ($line =~ /^PC51\^([A-Z0-9\-]+)\^([A-Z0-9\-]+)\^1\^/) {
            my ($from, $to) = ($1, $2);
            send_telnet("PC51^$to^$from^0^");
            #print_log('TX', "PC51^$to^$from^0^");
        }

        return;
    }

    print_log('RX', $line) if $state =~ /^await_/;
}

sub send_telnet {
    my ($msg) = @_;
    $msg =~ s/\r?\n$//;
    print $sock "$msg\n";
    my $visible = ($state eq 'await_password') ? '********' : $msg;
    print_log('TX', $visible);
}

sub send_pc92a {
    my $counter = get_counter();
    my $msg = "PC92^$mi_nodo^$counter^A^^5$mi_nodo:$mi_ip^H99^";
    send_telnet($msg);
}

sub send_pc92k {
    my $counter = get_counter();
    my $msg = "PC92^$mi_nodo^$counter^K^5$mi_nodo:9000:1^0^0^$mi_ip^$version^H99^";
    send_telnet($msg);
}

sub send_pc92c {
    my $counter = get_counter();
    my $users_msg = '';

    if (%active_users) {
        foreach my $user (keys %active_users) {
            my $user_ip = $active_users{$user}{ip};
            $users_msg .= "^1$user:$user_ip";
        }
    }

    my $msg = "PC92^$mi_nodo^$counter^C^5$mi_nodo$users_msg^H99^";
    send_telnet($msg);
}

sub get_counter {
    my ($s, $us) = gettimeofday();
    my @t = gmtime($s);
    my $seconds_since_midnight = $t[0] + $t[1]*60 + $t[2]*3600 + $us / 1_000_000;
    return sprintf("%.2f", $seconds_since_midnight);
}

sub get_public_ip {
    my $ip = get("http://ifconfig.me/ip") || '127.0.0.1';
    chomp($ip);
    return $ip;
}

sub reconnect_later {
    my $w; $w = AnyEvent->timer(
        after => 5,
        cb => sub {
            undef $w;
            $state = 'await_login';
            $buffer = '';
            $remote_node = '';
            cancel_login_timeout();
            connect_telnet();
        }
    );
}

sub start_login_timeout {
    cancel_login_timeout();
    $login_timeout_watcher = AnyEvent->timer(
        after => 10,
        cb    => sub {
            print_log('**', "Timeout waiting for login/password. Restarting connection...");
            reconnect_later();
        }
    );
}

sub cancel_login_timeout {
    undef $login_timeout_watcher if $login_timeout_watcher;
}

sub print_log {
    my ($tag, $msg) = @_;

    if ($filter_rx_only_specific_pc) {
        #if ($tag eq 'RX' && $msg !~ /^(PC51|PC11|PC61)\^/) {
        if ($tag eq 'RX' && $msg !~ /^(PC51)\^/) {
            return;
        }
    }

    my ($s, $us) = gettimeofday();
    my @t = localtime($s);
    printf("[%02d:%02d:%02d][%s] %s\n", $t[2], $t[1], $t[0], $tag, $msg);
}

sub check_pc92_timers {
    return unless $state eq 'ready';
    my $current_time = time;

    if ($current_time - $last_pc92c_time >= $pc92c_interval) {
        send_pc92c();
        $last_pc92c_time = $current_time;
    }

    if ($current_time - $last_pc92k_time >= $pc92k_interval) {
        send_pc92k();
        $last_pc92k_time = $current_time;
    }
}

sub start_mqtt {
    $mqtt = AnyEvent::MQTT->new(
        host => $mqtt_host,
        port => $mqtt_port,
        keep_alive_timer => 120,
    );

    my $subscribe_cv = $mqtt->subscribe(
        topic    => $mqtt_topic,
        callback => sub {
            my ($topic, $message) = @_;
            my $data = eval { decode_json($message) };
            if ($@) {
                # print "Error parsing JSON: $@\n";
            } else {
                # print "Call: $data->{call}, IP: $data->{ip}, TS: $data->{ts}\n";
                handle_mqtt_data($data);
            }
        }
    );

    $subscribe_cv->cb(sub {
        print_log('**', "MQTT subscription complete.");
    });
}

sub handle_mqtt_data {
    my ($data) = @_;
    my $call = uc $data->{call};
    my $ip   = $data->{ip};
    my $ts   = $data->{ts} || time;

    if (exists $active_users{$call}) {
        $active_users{$call}{ts} = $ts;
    } else {
        $active_users{$call} = { ip => $ip, ts => $ts };
        my $msg = "PC92^$mi_nodo^" . get_counter() . "^A^^1$call:$ip^H99^";
        send_telnet($msg);
        print_log('**', "New user connected: $call");
    }

    my $current_time = time;

    foreach my $user (keys %active_users) {
        if ($current_time - $active_users{$user}{ts} > $timeout_conn) {
            my $msg = "PC92^$mi_nodo^" . get_counter() . "^D^^1$user^H98^";
            send_telnet($msg);
            delete $active_users{$user};
            print_log('**', "User $user disconnected due to inactivity");
        }
    }
}

sub start_fifo {
    if (!-p $fifo_path) {
        unlink $fifo_path if -e $fifo_path;
        system("mkfifo", $fifo_path) == 0 or die "Could not create FIFO: $!";
    }

    open(my $fh, "<", $fifo_path) or die "Cannot open FIFO: $!";

    $fifo_watcher = AnyEvent->io(
        fh   => $fh,
        poll => 'r',
        cb   => sub {
            my $line = <$fh>;
            return unless defined $line;
            chomp $line;
            handle_fifo_line($line);
        }
    );
}

sub handle_fifo_line {
    my ($line) = @_;

    if ($line =~ /^CONN,([A-Z0-9\-]+),([\d\.]+)$/i) {
        my ($call, $ip) = (uc($1), $2);
        my $msg = "PC92^$mi_nodo^" . get_counter() . "^A^^1$call:$ip^H99^";
        send_telnet($msg);
        print_log('**', "FIFO: Connected $call from $ip");
    }
    elsif ($line =~ /^DESC,([A-Z0-9\-]+)$/i) {
        my $call = uc $1;
        my $msg = "PC92^$mi_nodo^" . get_counter() . "^D^^1$call^H98^";
        send_telnet($msg);
        print_log('**', "FIFO: Disconnected $call");
    }
    else {
        print_log('**', "FIFO: Invalid line: $line");
    }
}
