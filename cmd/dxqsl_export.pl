#
# Export QSL information from the local database
#
# Copyright (c) 2010 Dirk Koopman G1TLH
#

my ($self, $line) = @_;
my ($fn) = $line;
return (1, $self->msg('e5')) if $self->priv < 9;
return (1, "export_dxqsl: <pathname to export to>") unless $fn;

#$DB::single=1;

return (1, $self->msg('db3', 'QSL')) unless $QSL::dbm;

my $of = IO::File->new(">$fn") or return(1, $self->msg('e30', $fn));
$of->print(q{"call","manager","spots","unix timet","last spotter"}."\n");

my ($r, $k, $v, $flg, $count, $q);
for ($flg = R_FIRST; !$QSL::dbm->seq($k, $v, $flg); $flg = R_NEXT) {
	next unless $k;

	$q = QSL::get($k);
	if ($q) {
		for (@{$q->[1]}) {
			$of->print(join(',', $k, $_->[0], $_->[1], $_->[2], $_->[3]). "\n");
			++$count;
		}
	}
}
$of->close;
return(0, $self->msg("db13", $count, 'dxqsl', $fn));
