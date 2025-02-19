#
# show the version number of the software + copyright info
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @out;
my @in = map {uc} split /\s+/, $line;

if ($self->priv > 5 && @in) {
#		$DB::single=1;

	my $q = $in[0] eq 'ALL' ? '.*' : join('|', @in);
	my @n = sort {$a->call cmp $b->call} grep {$_->call =~ /^(?:$q)/} Route::Node::get_all();
	push @out, " Node      Version  Build  PC9X  via PC92";
	foreach my $n (@n) {
		push @out, sprintf " %-10s  %5d  %5s   %3s       %3s", $n->call, $n->version, $n->build, yesno($n->do_pc9x), yesno($n->via_pc92);
	}
	push @out, ' ' . scalar @n . " Nodes found";
} else {
	my ($year) = (gmtime($main::systime))[5];
	$year += 1900;
	push @out, "DXSpider v$main::version (build $main::build git: $main::gitbranch/$main::gitversion) using perl $^V on \u$^O";
	push @out, "Copyright (c) 1998-$year Dirk Koopman G1TLH";
}


return (1, @out);
