#
# This is a local command to generate the various statistics that
# can then be displayed on an MRTG plot
#
# Your mrtg binary must live in one of the standard places
#
# The arguments (keywords) to the mrtg command are these
#
# a) content          (you always get the node users and nodes and data in/out)
#    proc             - get the processor usage
#    agw              - include the AGW stats separately 
#    totalspots       - all spots
#    hfvhf            - all spots split into HF and VHF
#    wwv              - two graphs of WWV, one SFI and R other A and K
#    wcy              - WCY A and K 
#    pc92             - PC92 C and K, PC92 A and D
#    all              - all of the above 
#    
# b) actions          
#    test             - do everything except check for and run mrtg
#    nomrtg           - ditto (better name)
#    dataonly         - only generate the data files for mrtg
#    cfgonly          - only generate the mrtg.cfg file (like cfgmaker)
#    runmrtg          - run mrtg, this is probably used with dataonly
#                     - together with a home rolled mrtg.cfg 
#
# Copyright (c) 2002 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;

# create the arg list
my %want;
for (split /\s+/, $line) { $want{lc $_} = 1};
$want{nomrtg} = 1 if $want{cfgonly} || $want{test};
 			 
return (1, "MRTG not installed") unless $want{nomrtg} || -e '/usr/bin/mrtg' || -e '/usr/local/bin/mrtg';

my $mc = new Mrtg or return (1, "cannot initialise Mrtg $!");

# do Data in / out totals
my $din = $Msg::total_in;
my $dout = $Msg::total_out;
unless ($want{agw}) {
	$din += $AGWMsg::total_in;
	$dout += $AGWMsg::total_out;
}

$mc->cfgprint('msg', [], 64000, 
		 "Cluster Data <font color=#00cc00>in</font> and <font color=#0000ff>out</font> of $main::mycall",
		 'Bytes / Sec', 'Bytes In', 'Bytes Out') unless $want{dataonly};
$mc->data('msg', $din, $dout, "Data in and out of $main::mycall") unless $want{cfgonly};

# do AGW stats if they apply
if ($want{agw}) {
	$mc->cfgprint('agw', [], 64000, 
				  "AGW Data <font color=#00cc00>in</font> and <font color=#0000ff>out</font> of $main::mycall",
				  'Bytes / Sec', 'Bytes In', 'Bytes Out') unless $want{dataonly};
	$mc->data('agw', $AGWMsg::total_in, $AGWMsg::total_out, "AGW Data in and out of $main::mycall") unless $want{cfgonly};
}

if (!$main::is_win && ($want{proc} || $want{all})) {
	$ENV{COLUMNS} = 250;
	my $secs;
	my $f = new IO::File "ps ax -ocputime,args |";
#	dbg("$f");
	if ($f) {
		while (<$f>) {
			chomp;
			my $l = $_;
#			dbg($l);
			next unless $l =~ m{cluster\.pl$};
			next if $l =~ m{bash\s+\-c};
			my @f = split /\s+/, $l;
#			dbg("$f[9]");
			my ($d, $h, $m, $s) = $f[0] =~ /(?:(\d+)-)?(\d+):(\d\d):(\d\d)$/;
			$d ||= 0;
			$secs = ($d * 86400) + ($h * 3600) + ($m * 60) + $s;
			last;
		}
		$f->close;
	}
	if ($secs) {
		$mc->cfgprint('proc', [qw(noo perminute)], 5*60, 
					  "Processor Usage",
					  'Proc Secs / min', 'Proc Secs', 'Proc Secs') unless $want{dataonly};
		$mc->data('proc', $secs, $secs, "Processor Usage") unless $want{cfgonly};
	}
}

# do the users and nodes
my $users = DXChannel::get_all_users();
my $nodes = DXChannel::get_all_nodes();

$mc->cfgprint('users', [qw(unknaszero gauge)], 500, 
		 "<font color=#00cc00>Users</font> and <font color=#0000ff>Nodes</font> on $main::mycall",
		 'Users / Nodes', 'Users', 'Nodes') unless $want{dataonly};
$mc->data('users', $users, $nodes, 'Users / Nodes') unless $want{cfgonly};

# do the  total users and nodes
if ($want{totalusers} || $want{all}) {
	$nodes = Route::Node::count();
	$users = Route::User::count();
	$mc->cfgprint('totalusers', [qw(unknaszero gauge)], 10000, 
			'Total <font color=#00cc00>Users</font> and <font color=#0000ff>Nodes</font> in the Visible Cluster Network',
			 'Users / Nodes', 'Users', 'Nodes') unless $want{dataonly};
	$mc->data('totalusers', $users, $nodes, 'Total Users and Nodes in the Visible Cluster Network') unless $want{cfgonly};
}

# do the total spots
if ($want{totalspots} || $want{all}) {
	$mc->cfgprint('totalspots',  [qw(unknaszero gauge noi)], 1000, 'Total Spots',
			 'Spots / min', 'Spots', 'Spots') unless $want{dataonly};
	$mc->data('totalspots', int ($Spot::totalspots/5+0.5), int($Spot::totalspots/5+0.5), 'Total Spots') unless $want{cfgonly};
	$Spot::totalspots = 0;
}

# do the HF and VHF spots
if ($want{hfvhf} || $want{all}) {
	$mc->cfgprint('hfspots', [qw(unknaszero gauge)], 1000, '<font color=#00cc00>HF</font> and <font color=#0000ff>VHF+</font> Spots',
			 'Spots / min', 'HF', 'VHF') unless $want{dataonly};
	$mc->data('hfspots', int($Spot::hfspots/5+0.5), int($Spot::vhfspots/5+0.5), 'HF and VHF+ Spots') unless $want{cfgonly};
	$Spot::hfspots = $Spot::vhfspots = 0;
}

# wwv stuff
if ($want{wwv} || $want{all}) {
	$mc->cfgprint('wwvsfi', [qw(gauge)], 1000, 'WWV <font color=#00cc00>SFI</font> and <font color=#0000ff>R</font>', 'SFI / R', 'SFI', 'R') unless $want{dataonly};
	$mc->data('wwvsfi', ($Geomag::sfi || $WCY::sfi), ($Geomag::r || $WCY::r), 'WWV SFI and R') unless $want{cfgonly};
	$mc->cfgprint('wwvka', [qw(gauge)], 1000, 'WWV <font color=#00cc00>A</font> and <font color=#0000ff>K</font>',
			 'A / K', 'A', 'K') unless $want{dataonly};
	$mc->data('wwvka', $Geomag::a, $Geomag::k, 'WWV A and K') unless $want{cfgonly};
}

# WCY stuff
if ($want{wcy} || $want{all}) {
	$mc->cfgprint('wcyka', [qw(gauge)], 1000, 'WCY <font color=#00cc00>A</font> and <font color=#0000ff>K</font>',
			 'A / K', 'A', 'K') unless $want{dataonly};
	$mc->data('wcyka', $WCY::a, $WCY::k, 'WCY A and K') unless $want{cfgonly};
}

if ($want{pc92} || $want{all}) {

	$mc->cfgprint('pc92ck', [], 1024000,
				  "PC92 <font color=#00cc00>C</font> and <font color=#0000ff>K</font> records into $main::mycall",
				  'Bytes / Sec', 'C', 'K') unless $want{dataonly};
	$mc->data('pc92ck', $DXProt::pc92Cin, $DXProt::pc92Kin, "PC92 C and K into $main::mycall") unless $want{cfgonly};
#	$DXProt::pc92Cin = $DXProt::pc92Kin = 0;

	$mc->cfgprint('pc92ad', [], 1024000,
				  "PC92 <font color=#00cc00>A</font> and <font color=#0000ff>D</font> records into $main::mycall",
				  'Bytes / Sec', 'A', 'D') unless $want{dataonly};
	$mc->data('pc92ad', $DXProt::pc92Ain, $DXProt::pc92Din, "PC92 A and D into $main::mycall") unless $want{cfgonly};
#	$DXProt::pc92Ain = $DXProt::pc92Din = 0;

}

# 
# do the mrtg thing
#

my @out;
{
local %ENV;
$ENV{LANG} = 'C';
@out = $mc->run unless $want{nomrtg};
}
return (1, @out);
