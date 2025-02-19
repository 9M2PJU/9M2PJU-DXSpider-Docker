#
# Obtain the latest keps from the Amsat site and
# load them. 
#
# This will clear out the old keps and rewrite the $root/local/Keps.pm 
# file to retain the data.
#
# The main state machine code comes more or less straight out of convkeps.pl
# This command is really to avoid the (even more) messy business of parsing emails
#
# Copyright (c) 2013 Dirk Koopman, G1TLH
#

# convert (+/-)00000-0 to (+/-).00000e-0
sub genenum
{
	my ($sign, $frac, $esign, $exp) = unpack "aa5aa", shift;
	$esign = '+' if $esign eq ' ';
	my $n = $sign . "." . $frac . 'e' . $esign . $exp;
	return $n - 0;
}

sub on_disc
{
	my $conn = shift;
	my $dxchan = shift;
	
	if ($conn->{kepsin}) {
		my $fn = "$main::root/local/Keps.pm";
		my %keps;
		
		my @lines = split /[\r\n]+/, $conn->{kepsin};
		my $state = 1;
		my $line = 0;
		my $ref;
		my $count = 0;
		my $name;
		my %lookup = (
					  'AO-5' => 'AO-05',
					  'AO-6' => 'AO-06',
					  'AO-7' => 'AO-07',
					  'AO-8' => 'AO-08',
					  'AO-9' => 'AO-09',
					 );
		for (@lines) {
			
			last if m{^-};

			s/^\s+//;
			s/[\s\r]+$//;
			next unless $_;
			last if m{^/EX}i;
			
			dbg("keps: $state $_") if isdbg('keps');
			
			if ($state == 0 && /^Decode/i) {
				$state = 1;
			} elsif ($state == 1) {
				last if m{^-};
				next if m{^To\s+all}i;
				
				if (/^([- \w]+)(?:\s+\[[-+\w]\])?$/) {
					my $n = uc $1;
					dbg("keps: $state processing $n") if isdbg('keps');
					$n =~ s/\s/-/g;
					$name = $lookup{$n};
					$name ||= $n;
					$ref = $keps{$name} = {}; 
					$state = 2;
				}
			} elsif ($state == 2) {
				if (/^1 /) {
					my ($id, $number, $epoch, $decay, $mm2, $bstar, $elset) = unpack "xxa5xxa5xxxa15xa10xa8xa8xxxa4x", $_;
					dbg("keps: $state processing line 1 for $name") if isdbg('keps');
					$ref->{id} = $id - 0;
					$ref->{number} = $number - 0;
					$ref->{epoch} = $epoch - 0;
					$ref->{mm1} = $decay - 0;
					$ref->{mm2} = genenum($mm2);
					$ref->{bstar} = genenum($bstar);
					$ref->{elset} = $elset - 0;
					#print "$id $number $epoch $decay $mm2 $bstar $elset\n"; 
					#print "mm2: $ref->{mm2} bstar: $ref->{bstar}\n";
					
					$state = 3;
				} else {
					#print "out of order on line $line\n";
					dbg("keps: $state invalid or out of order line 1 for $name") if isdbg('keps');
					undef $ref;
					delete $keps{$name} if defined $name;
					$state = 1;
				}
			} elsif ($state == 3) {
				if (/^2 /) {
					my ($id, $incl, $raan, $ecc, $peri, $man, $mmo, $orbit) = unpack "xxa5xa8xa8xa7xa8xa8xa11a5x", $_;
					dbg("keps: $state processing line 2 for $name") if isdbg('keps');
					$ref->{meananomaly} = $man - 0;
					$ref->{meanmotion} = $mmo - 0;
					$ref->{inclination} = $incl - 0;
					$ref->{eccentricity} = ".$ecc" - 0;
					$ref->{argperigee} = $peri - 0;
					$ref->{raan} = $raan - 0;
					$ref->{orbit} = $orbit - 0;
					$count++;
				} else {
					#print "out of order on line $line\n";
					dbg("keps: $state invalid or out of order line 2 for $name") if isdbg('keps');
					delete $keps{$name};
				}
				undef $ref;
				$state = 1;
			}
		}
		if ($count) {
			dbg("keps: $count recs, creating $fn") if isdbg('keps');
			my $dd = new Data::Dumper([\%keps], [qw(*keps)]);
			$dd->Indent(1);
			$dd->Quotekeys(0);
			open(OUT, ">$fn") or die "$fn $!";
			print OUT "#\n# this file is automatically produced by the get/keps command\n#\n";
			print OUT "# Last update: ", scalar gmtime, "\n#\n";
			print OUT "\npackage Sun;\n\n";
			print OUT $dd->Dumpxs;
			print OUT "1;\n";
			close(OUT);
			dbg("keps: running load/keps") if isdbg('keps');
			dbg("keps: clearing out old keps") if isdbg('keps');
			%Sun::keps = ();
			$dxchan->send($dxchan->run_cmd("load/keps"));
		}
	}
}

sub process
{
	my $conn = shift;
	my $msg = shift;

	$conn->{kepsin} .= "$msg\n";
	
#	dbg("keps in: $msg") if isdbg('keps');
}

sub handle
{
	my ($self, $line) = @_;
	my $call = $self->call;
	my @out;

	$line = uc $line;
	return (1, $self->msg('e24')) unless $Internet::allow;
	return (1, $self->msg('e5')) if $self->priv < 8;
	my $target = $Internet::keps_url || 'www.amsat.org';
	my $path = $Internet::keps_path || '/amsat/ftp/keps/current/nasa.all';
	my $port = 80;

	dbg("keps: contacting $target:$port") if isdbg('keps');

	Log('call', "$call: show/keps $line");
	my $conn = AsyncMsg->post($self, $target, $port, $path, 
							  filter => \&process,
							  on_disc => \&on_disc);
	
	if ($conn) {
		push @out, $self->msg('m21', "show/keps");
	} else {
		push @out, $self->msg('e18', 'get/keps error');
	}

	return (1, @out);
}
