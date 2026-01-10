#
# DXSpider data summary
#
# Use: summary (sum)
#
# Copy in /spider/local_cmd/summary.pl
#
# Kin EA3CV, ea3cv@cronux.net
#
# 20250608 v1.9
#

use strict;
use warnings;
use Cwd 'abs_path';

my $self = shift;
return 1 unless $self->priv >= 5;

my @out;

push @out, "-" x 80;
push @out, sprintf "%22s %-10s        %8s %-10s", "Node:", $main::mycall, "Sysop:", $main::myalias;
push @out, "-" x 80;
push @out, sprintf "%10s%-8s %-6s        %-4s %-7s        %-7s %-10s",
   "", "Version:", $main::version,
    "Build:", $main::build,
    "Uptime:", main::uptime();
push @out, "-" x 80, " ";

# Obtener información del sistema
my $distro       = qx(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"');
my $perl_version = $^V;
my $hostname     = qx(hostname);
my $current_path = abs_path(".");
my $disk_usage   = qx(df -h "$current_path" | awk 'NR==2 {print \$5}');
chomp($_) for ($distro, $hostname, $disk_usage);

# Obtener locale de forma portátil (soporta Alpine, Docker, etc.)
my $locale = qx(locale 2>/dev/null | grep '^LANG=' | cut -d= -f2);
chomp($locale);
$locale = "" if $locale =~ /^\s*$/;

push @out, "------------------------------------ Host --------------------------------------";
push @out, sprintf "%22s %-20s", "Host:", $hostname;
push @out, sprintf "%22s %-10s        %8s %-10s", "Distro:", $distro, "Perl:", $perl_version;
push @out, sprintf "%22s %-10s             %8s %-10s", "Path:", $current_path, "Disk usage:", $disk_usage;
push @out, sprintf "%22s %-20s", "Locale:", $locale;
push @out, " ";

# Información de red
push @out, "---------------------------------- Public IP -----------------------------------";
push @out, sprintf "%22s %-20s", "Public IPv4:", $main::localhost_alias_ipv4;
push @out, sprintf "%22s %-20s", "Public IPv6:", $main::localhost_alias_ipv6;
push @out, " ";

# IP local
push @out, "----------------------------------- Local IP -----------------------------------";
push @out, sprintf "%22s %-20s", "Local IP:", join(", ", @main::localhost_names);
push @out, " ";

# Puertos de escucha
push @out, "--------------------------------- Listen Port ----------------------------------";
if (@main::listen) {
    push @out, map { sprintf "%40s/%d", $_->[0], $_->[1] } @main::listen;
} else {
    push @out, "Error: No hay datos en \@main::listen";
}
push @out, " ";

# Depuración
push @out, "------------------------------------ Debug -------------------------------------";
push @out, sprintf "%22s %-20s", "Default Debug:", join(", ", @main::debug);
push @out, sprintf "%22s %-20s", "Current Debug:", join(", ", sort keys %DXDebug::dbglevel);
push @out, " ";

# Total de peers y usuarios
push @out, "----------------------------- Total Peers/Users --------------------------------";

my ($total_peers, $reg_peers, $pass_peers) = (0, 0, 0);
foreach my $dxchan (DXChannel::get_all_nodes()) {
    next if $dxchan->call eq $main::mycall;
    my $ref = DXUser::get_current(uc $dxchan->call) || {};
    $total_peers++;
    $reg_peers++  if $ref->{registered} && $ref->{registered} eq "1";
    $pass_peers++ if $ref->{passwd};
}

my ($total_users, $reg_users, $pass_users) = (0, 0, 0);
foreach my $dxchan (DXChannel::get_all_users()) {
    my $ref = DXUser::get_current(uc $dxchan->call) || {};
    $total_users++;
    $reg_users++  if $ref->{registered} && $ref->{registered} eq "1";
    $pass_users++ if $ref->{passwd};
}

push @out, sprintf "%18s%4d%19s%5d", "Peers Nodes:", $total_peers, "Total Users:", $total_users;
push @out, sprintf "%18s%4d%19s%5d", "Register:", $reg_peers, "Register:", $reg_users;
push @out, sprintf "%18s%4d%19s%5d", "Password:", $pass_peers, "Password:", $pass_users;
push @out, " ";

# Spots
push @out, "--------------------------------- Total Spots ----------------------------------";
push @out, sprintf "%22s %-10s        %8s %-10s", "Total Spots:", $Spot::totalspots, "Total S. HF:", $Spot::hfspots;
push @out, " ";

# Consola
push @out, "----------------------------------- Console ------------------------------------";
push @out, sprintf "%22s %-10s        %8s %-10s", "IP Addr:", $main::clusteraddr, "Port:", $main::clusterport;
push @out, " ";

push @out, "---------------------------------- Security ------------------------------------";
push @out, " ";
push @out, "                             Register:    \$main::reqreg = ".$main::reqreg;
push @out, "                             Password:    \$main::passwdreq = ".($main::passwdreq // 0);
push @out, " ";
push @out, "--------------------------------- Users Vars -----------------------------------";
push @out, " ";
push @out, "                         Highest SSID:    \$main::max_ssid = ".$main::max_ssid;
push @out, "            Max num simultaneous conn:    \$main::maxconnect_user = ".$main::maxconnect_user;
push @out, "    Allow new conn to disconn old (1):    \$main::bumpexisting = ".$main::bumpexisting;
push @out, "       Min (ms) between conn per user:    \$main::min_reconnection_rate = ".$main::min_reconnection_rate;
push @out, "    Don't allow dx by <othercall> (0):    \$main::allowdxby = ".$main::allowdxby;
push @out, " Max concurrent errors before disconn:    \$DXChannel::maxerrors = ".$DXChannel::maxerrors;
push @out, "     Bad words allowed before disconn:    \$DXCommandmode::maxbadcount = ".$DXCommandmode::maxbadcount;
push @out, "  Remove all auto generated FTx spots:    \$DXProt::remove_auto_ftx = ".$DXProt::remove_auto_ftx;
push @out, " ";
push @out, "--------------------------------- Node Vars ------------------------------------";
push @out, " ";
push @out, "         Max number simultaneous conn:    \$main::maxconnect_node = ".$main::maxconnect_node;
push @out, "                   Max connlist pairs:    \$DXUser::maxconnlist = ".$DXUser::maxconnlist;
push @out, "       Max age of lastseen. Users (s):    \$DXUser::tooold = ".$DXUser::tooold;
push @out, "   Max age of lastin. Users/Nodes (s):    \$DXUser::veryold = ".$DXUser::veryold;
push @out, " ";
push @out, "--------------------------------- Spots Vars -----------------------------------";
push @out, " ";
push @out, "                        Slot Time  (s):    \$Spot::timegranularity = ".$Spot::timegranularity;
push @out, "                        Slot QRG (kHz):    \$Spot::qrggranularity = ".$Spot::qrggranularity;
push @out, "                        Dupe Page  (s):    \$Spot::dupage = ".$Spot::dupage;
push @out, "                        Autospot (kHz):    \$Spot::minselfspotqrg = ".$Spot::minselfspotqrg;
push @out, "           Length text in the deduping:    \$Spot::duplth = ".$Spot::duplth;
push @out, "             Max length call for dupes:    \$Spot::maxcalllth = ".$Spot::maxcalllth;
push @out, "           Remove node field from dupe:    \$Spot::no_node_in_dupe = ".$Spot::no_node_in_dupe;
push @out, "                   Max spots to return:    \$Spot::maxspots = ".$Spot::maxspots;
push @out, "                   Max days to go back:    \$Spot::maxdays = ".$Spot::maxdays;
push @out, "                       Cache spot days:    \$Spot::spotcachedays = ".$Spot::spotcachedays;
push @out, "       Granularity input time Spot (s):    \$Spot::spotage = ".$Spot::spotage;
push @out, "                             Bad spots:    \$DXProt::senderverify = ".$DXProt::senderverify;
push @out, " ";
push @out, "        Enable/disable 'node' checking:    \$Spot::do_node_check = ".$Spot::do_node_check;
push @out, "        Enable/disable 'call' checking:    \$Spot::do_call_check = ".$Spot::do_call_check;
push @out, "          Enable/disable 'by' checking:    \$Spot::do_by_check = ".$Spot::do_by_check;
push @out, "      Enable/disable 'ipaddr' checking:    \$Spot::do_ipaddr_check = ".$Spot::do_ipaddr_check;
push @out, " ";
push @out, " Check 'call' is not spotted too often:    \$Spot::dupecall = ".$Spot::dupecall;
push @out, "Threshold 'call' to become a duplicate:    \$Spot::dupecallthreshold = ".$Spot::dupecallthreshold;
push @out, " Check 'node' is not spotted too often:    \$Spot::nodetime = ".$Spot::nodetime;
push @out, "Threshold 'node' to become a duplicate:    \$Spot::nodetimethreshold = ".$Spot::nodetimethreshold;
push @out, " ";
push @out, "---------------------------------- RBN Vars ------------------------------------";
push @out, " ";
push @out, "                                Byte Q:    \$RBN::minqual = ".$RBN::minqual;
push @out, "                       Respot time (s):    \$RBN::respottime = ".$RBN::respottime;
push @out, " ";
push @out, "---------------------------------- PC92 Vars -----------------------------------";
push @out, " ";
push @out, "                              PC92 A/D:    \$DXProt::pc92_ad_enabled = ".$DXProt::pc92_ad_enabled;
push @out, "                           PC92 IPaddr:    \$DXProt::pc92c_ipaddr_enable = ".$DXProt::pc92c_ipaddr_enable;
push @out, " Period between outgoing PC92C updates:    \$DXProt::pc92_update_period = ".$DXProt::pc92_update_period;
push @out, "    Shorten update after conn/start up:    \$DXProt::pc92_short_update_period = ".$DXProt::pc92_short_update_period;
push @out, "      Update period for external nodes:    \$DXProt::pc92_extnode_update_period = ".$DXProt::pc92_extnode_update_period;
push @out, "            Frequency of PC92K records:    \$DXProt::pc92_keepalive_period = ".$DXProt::pc92_keepalive_period;
push @out, "      Maximum time to wait for a reply:    \$DXProt::pc92_find_timeout = ".$DXProt::pc92_find_timeout;
push @out, "Delay for PC92A to be sent before spot:    \$DXProt::pc92_slug_changes = ".$DXProt::pc92_slug_changes;
push @out, " ";

# Filtros de nodo
my $call = "node_default";
push @out, "-------------------------------- Node Filters ----------------------------------";
for my $sort (qw(route ann spots wcy wwv rbn)) {
    for my $flag (1, 0) {
        if (my $ref = Filter::read_in($sort, $call, $flag)) {
            push @out, $ref->print($call, $sort, $flag ? "input" : "");
            push @out, " ";
        }
    }
}

# Directorios a inspeccionar
my $dir_local = "/spider/local";
my $dir_connect = "/spider/connect";

# Listar archivos .pm en spider/local/ (excluyendo archivos ocultos)
push @out, " ";
push @out, "---------------------------------- local dir -----------------------------------";
if (-d $dir_local) {
    opendir(my $dh, $dir_local) or die "No se puede abrir $dir_local: $!\n";
    push @out, sprintf("Modules in %s:", $dir_local);
    my @files = grep { /^[^\.].*\.pm$/ } readdir($dh); # Excluir archivos ocultos y filtrar .pm
    closedir($dh);

    @files = sort @files;  # Ordenar alfabéticamente
    push @out, map { sprintf("%27s%s", "", $_) } @files;  # Desplazamiento de 10 espacios
} else {
    push @out, sprintf("El directorio %s no existe.", $dir_local);
}

# Listar todos los archivos en spider/connect/ (excluyendo archivos ocultos)
push @out, " ";
push @out, "--------------------------------- connect dir ----------------------------------";
if (-d $dir_connect) {
    opendir(my $dh, $dir_connect) or die "No se puede abrir $dir_connect: $!\n";
    push @out, sprintf("Connection files in %s:", $dir_connect);
    my @files = grep { !/^\./ } readdir($dh); # Excluir archivos ocultos
    closedir($dh);

    @files = sort @files;  # Ordenar alfabéticamente
    push @out, map { sprintf("%38s%s", "", $_) } @files;  # Desplazamiento de 10 espacios
} else {
    push @out, sprintf("El directorio %s no existe.", $dir_connect);
}

# Conexiones de nodos detalladas

my $dxchan;
my $tnow = time();
push @out, " ";
push @out, "---------------------------------- Node List -----------------------------------";
push @out, "Node      R P  Type  IP Address      Port   Dir.  State   Cnum  Connection Time";
push @out, "--------  - -  ----  --------------- -----  ----  ------  ----  ---------------";

foreach $dxchan ( sort {$a->call cmp $b->call} DXChannel::get_all ) {
    my $call = $dxchan->call();
    # Ignorar si el call es igual a $main::mycall
    next if defined $main::mycall && $call eq $main::mycall;
    my $t = cldatetime($dxchan->startt);
    my $type = $dxchan->is_node ? "NODE" : "USER";
    my $sort = "    ";
    if ($dxchan->is_node) {
        $sort = "DXSP" if $dxchan->is_spider;
        $sort = "CLX " if $dxchan->is_clx;
        $sort = "DXNT" if $dxchan->is_dxnet;
        $sort = "AR-C" if $dxchan->is_arcluster;
        $sort = "AK1A" if $dxchan->is_ak1a;
        $sort = "CCCL" if $dxchan->is_ccluster;
    }

    my ($conn, $state) = ($dxchan->conn, $dxchan->state);
    my ($ip, $port, $dir, $cnum, $reg) = @{$conn}{qw(peerhost peerport sort cnum csort)};

    $dir = $dir eq "Incoming" ? "IN" : $dir eq "Outgoing" ? "OUT" : $dir;

    my $reg = (DXUser::get_current($call) // {})->{registered} eq "1" ? "R" : "";
    my $pass = (DXUser::get_current($call) // {})->{passwd} ? "P" : "";


    my $delta = $tnow - $dxchan->startt;
    my $time_on = sprintf("%3d d%3d h %3d m", int($delta/(24*60*60)), int(($delta/(60*60))%24), int(($delta/60)%60));

    if ($type eq "NODE") {
        push @out, sprintf "%-9s %1s %1s  %-4s  %-15s %-6s %-5s %-6s %5s $time_on",
            $call, $reg, $pass, $sort, $ip, $port, $dir, $state, $cnum;
        }
}

# Conexiones de usuarios detalladas
push @out, " ";
push @out, "---------------------------------- Users List ----------------------------------";
push @out, "User      R P  Type  IP Address      Port   Dir.  State   Cnum  Connection Time";
push @out, "--------  - -  ----  --------------- -----  ----  ------  ----  ---------------";

foreach $dxchan ( sort {$a->call cmp $b->call} DXChannel::get_all ) {
    my $call = $dxchan->call();
    # Ignorar si el call es igual a $main::mycall
    next if defined $main::mycall && $call eq $main::mycall;
    my $t = cldatetime($dxchan->startt);
    my $type = $dxchan->is_node ? "NODE" : "USER";
    my $sort = "    ";
    if (!$dxchan->is_node || $dxchan->is_rbn) {
        $sort = "LOCL" if $dxchan->conn->isa('IntMsg');
        $sort = "WEB " if $dxchan->is_web;
        $sort = "EXT " if $dxchan->conn->isa('ExtMsg');
        $sort = "RBN " if $dxchan->is_rbn;
    }

    my ($conn, $state) = ($dxchan->conn, $dxchan->state);
    my ($ip, $port, $dir, $cnum, $reg) = @{$conn}{qw(peerhost peerport sort cnum csort)};

    $dir = $dir eq "Incoming" ? "IN" : $dir eq "Outgoing" ? "OUT" : $dir;

    my $reg = (DXUser::get_current($call) // {})->{registered} eq "1" ? "R" : "";
    my $pass = (DXUser::get_current($call) // {})->{passwd} ? "P" : "";


    my $delta = $tnow - $dxchan->startt;
    my $time_on = sprintf("%3d d%3d h %3d m", int($delta/(24*60*60)), int(($delta/(60*60))%24), int(($delta/60)%60));

    if ($type eq "USER") {
        push @out, sprintf "%-9s %1s %1s  %-4s  %-15s %-6s %-5s %-6s %5s $time_on",
            $call, $reg, $pass, $sort, $ip, $port, $dir, $state, $cnum;
        }
}

# Peers

my $dxchan;
push @out, " ";
push @out, "-------------------------------- Partners List ---------------------------------";
push @out, "Node      Type  Version  Build  R  P  Priv  Isolate";
push @out, "--------  ----  -------  -----  -  -  ----  -------";

foreach $dxchan ( sort {$a->call cmp $b->call} DXChannel::get_all ) {
    my $call = $dxchan->call();
    # Ignorar si el call es igual a $main::mycall
    next if defined $main::mycall && $call eq $main::mycall;
    my $t = cldatetime($dxchan->startt);
    my $type = $dxchan->is_node ? "NODE" : "USER";
    my $sort = "    ";
    if ($dxchan->is_node) {
        $sort = "DXSP" if $dxchan->is_spider;
        $sort = "CLX " if $dxchan->is_clx;
        $sort = "DXNT" if $dxchan->is_dxnet;
        $sort = "AR-C" if $dxchan->is_arcluster;
        $sort = "AK1A" if $dxchan->is_ak1a;
        $sort = "CCCL" if $dxchan->is_ccluster;
    }

    my ($conn, $state) = ($dxchan->conn, $dxchan->state);
    my ($ip, $port, $dir, $cnum, $reg) = @{$conn}{qw(peerhost peerport sort cnum csort)};

    my $priv = (DXUser::get_current($call) // {})->{priv};
#    my $lock = (DXUser::get_current($call) // {})->{lockout} eq "1" ? "Y" : "";
    my $version = (Route::Node::get($call) // {})->{version};
    my $build = (Route::Node::get($call) // {})->{build};
#    my $badnode = ($DXProt::badnode->in($call)) eq "1" ? "Y" : "";
    my $reg = (DXUser::get_current($call) // {})->{registered} eq "1" ? "R" : "";
    my $pass = (DXUser::get_current($call) // {})->{passwd} ? "P" : "";
    my $isolate = (DXUser::get_current($call) // {})->{isolate} ? "Y" : "";

if ($type eq "NODE") {
    push @out, sprintf "%-9s %-4s %7s %6s %3s %2s %4s %6s",
                $call, $sort, $version, $build, $reg, $pass, $priv, $isolate;
}

}
push @out, " ";

return (1, @out);
