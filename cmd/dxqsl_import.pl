#
# Import QSL information to the local database
#
# Copyright (c) 2010 Dirk Koopman G1TLH
#

my ($self, $line) = @_;
my ($fn) = $line;
return (1, $self->msg('e5')) if $self->priv < 9;
return (1, "import_dxqsl: <pathname to import from>") unless $fn;

#$DB::single=1;

return (1, $self->msg('db3', 'QSL')) unless $QSL::dbm;

my $if = IO::File->new("$fn") or return(1, $self->msg('e30', $fn));
my $count;
while (<$if>) {
	next if /^\s+"/;
	chomp;
	my ($call, $manager, $c, $t, $by) = split /\s*,\s*/;
	if ($call && $by) {
		my $q = QSL::get($call) || QSL->new($call);
		my ($r) = grep {$_->[0] eq $manager} @{$q->[1]};
		if ($r) {
			$r->[1] += $c;
			if ($t > $r->[2]) {
				$r->[2] = $t;
				$r->[3] = $by;
			}
		} else {
			$r = [$manager, $by, $t, $by];
			unshift @{$q->[1]}, $r;
		}
		$q->put;
		++$count;
	}
}

$if->close;

return(0, $self->msg("db10", $count, $fn, 'dxqsl'));
