#
# show/registered
#
# show all registered users 
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) unless $self->priv >= 9;

my @out;
my @val;

use DB_File;

if ($line) {
	$line =~ s/[^\w\-\/]+//g;
	$line = "\U\Q$line";
}

my %call = ();
$call{$_} = 1 for split /\s+/, $line;
delete $call{'ALL'};

my ($action, $count, $key, $data) = (0,0,0,0);
unless (keys %call) {
	for ($action = DXUser::R_FIRST, $count = 0; !$DXUser::dbm->seq($key, $data, $action); $action = DXUser::R_NEXT) {
		if ($data =~ m{registered}) {
			$call{$key} = 1;       # possible candidate
		}
	}
}

foreach $key (sort keys %call) {
	my $u = DXUser::get_current($key);
	if ($u && defined (my $r = $u->registered)) {
		push @val, "${key}($r)";
		++$count;
	}
	
}

my @l;
push @out, "Registration is " . ($main::reqreg ? "Required" :  "NOT Required");
foreach my $call (@val) {
	if (@l >= 5) {
		push @out, sprintf "%-12s %-12s %-12s %-12s %-12s", @l;
		@l = ();
	}
	push @l, $call;
}
if (@l) {
	push @l, "" while @l < 5;
	push @out, sprintf "%-12s %-12s %-12s %-12s %-12s", @l;
}

push @out, $self->msg('rec', $count);
return (1, @out);


