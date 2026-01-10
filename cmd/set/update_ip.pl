#
#  update_ip.pl — Update public and local IPs for DXSpider
#
#  Description:
#    Updates DXSpider runtime IP-related variables:
#      - $main::localhost_alias_ipv4 : public IPv4 address
#      - $main::localhost_alias_ipv6 : public IPv6 address (if any)
#      - @main::localhost_names      : list of known local IPs (127.0.0.1, ::1, etc.)
#
#    This is essential to ensure proper behavior in multi-host, VM, container,
#    or NAT/firewalled environments where DXSpider needs to recognize internal clients.
#
#    It logs and shows changes:
#      - Public IP changes (IPv4 or IPv6)
#      - Local IP additions/removals
#
#  Usage:
#    From DXSpider shell (as a self command):
#      set/update_ip                      # Auto-detects current public and local IP
#      set/update_ip 192.168.1.100        # Adds one or more local LAN IPs
#      set/update_ip 10.0.0.5 172.18.0.3
#
#    From crontab (e.g., every 10 minutes):
#      00,10,20,30,40,50 * * * * run_cmd("set/update_ip 192.168.1.100 172.18.0.3")
#
#    ⚠️ Only local IP addresses (not public) should be passed as arguments.
#
#  Installation:
#    Save as: /spider/local_cmd/set/update_ip.pl
#
#  Requirements:
#    - Internet access to detect public IPs (via curl)
#
#  Author  : Kin EA3CV (ea3cv@cronux.net)
#  Version : 20250410 v1.11
#
#  Note:
#    Designed to prevent loss of SPOTS/ANN due to incorrect IPs.
#

use strict;
use warnings;

my ($self, $line) = @_;
my @custom = split(/\s+/, $line);
my @out;

# Obtener IPv4 e IPv6 públicas por separado
my $pub_ipv4 = `curl -4 -s ifconfig.me`; chomp($pub_ipv4);
my $pub_ipv6 = `curl -6 -s ifconfig.me`; chomp($pub_ipv6);

# --- IPv4 ---
my $old_ipv4 = $main::localhost_alias_ipv4 || '';
if ($pub_ipv4 =~ /^[\d\.]+$/) {
    if ($pub_ipv4 ne $old_ipv4) {
        $main::localhost_alias_ipv4 = $pub_ipv4;
        push @out, "\nPublic IPv4 change: $pub_ipv4 (previous $old_ipv4)";
    } else {
        push @out, "No public IPv4 change: $pub_ipv4";
    }
} else {
    push @out, "No public IPv4 available";
}

# --- IPv6 ---
my $old_ipv6 = $main::localhost_alias_ipv6 || '';
if ($pub_ipv6 =~ /:/) {
    if ($pub_ipv6 ne $old_ipv6) {
        $main::localhost_alias_ipv6 = $pub_ipv6;
        push @out, "Public IPv6 change: $pub_ipv6 (previous $old_ipv6)";
    } else {
        push @out, "No public IPv6 change: $pub_ipv6";
    }
} else {
    push @out, "No public IPv6 available";
}

# --- Local IPs ---
my @system_ips = qw(127.0.0.1 ::1);

my $hostname_ips = `hostname -I`;
my @system_detected = split(/\s+/, $hostname_ips);
chomp(@system_detected);

# Eliminar duplicados globalmente
my %seen;
my @detected_unique = grep { $_ ne '' && !$seen{$_}++ } @system_detected;
my @custom_sorted = sort @custom;

my %ip_seen;
my @new_list = grep { $_ ne '' && !$ip_seen{$_}++ }
               (@system_ips, @detected_unique, @custom_sorted);

my @old_list = @main::localhost_names;
my %old_map = map { $_ => 1 } @old_list;
my %new_map = map { $_ => 1 } @new_list;

my @added   = grep { !$old_map{$_} } @new_list;
my @removed = grep { !$new_map{$_} } @old_list;

if (@added || @removed) {
    @main::localhost_names = @new_list;
    my $joined = join(' ', @new_list);
    push @out, "Local IPs changes: $joined";
} else {
    my $joined = join(' ', @new_list);
    push @out, "No local IPs change: $joined";
}

# --- Actualizar el fichero /spider/scripts/startup ---
my $startup_file = '/spider/scripts/startup';

# Leer líneas existentes
open(my $in, '<', $startup_file) or die "Cannot open $startup_file: $!";
my @lines = <$in>;
close($in);

# Crear nueva configuración
my $ipv4_line   = "set/var \$main::localhost_alias_ipv4 = '$main::localhost_alias_ipv4';\n";
my $ipv6_line   = "set/var \$main::localhost_alias_ipv6 = '$main::localhost_alias_ipv6';\n";
my $names_line  = "set/var \@main::localhost_names = qw(@main::localhost_names);\n";

# Filtrar líneas previas de esas variables
@lines = grep {
    !/\$main::localhost_alias_ipv4/ &&
    !/\$main::localhost_alias_ipv6/ &&
    !/\@main::localhost_names/
} @lines;

# Insertar nuevas líneas consecutivas al final
#push @lines, "\n# Updated localhost IP definitions\n", $ipv4_line, $ipv6_line, $names_line;
push @lines, $ipv4_line, $ipv6_line, $names_line;

# Escribir el fichero actualizado
open(my $out_fh, '>', $startup_file) or die "Cannot write to $startup_file: $!";
print $out_fh @lines;
close($out_fh);

push @out, "Updated /spider/scripts/startup with current IP definitions.";

return (1, @out);
