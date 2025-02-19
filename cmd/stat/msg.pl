#
# show all the values on a message header
#
#
#

my ($self, $line) = @_;
my @list = split /\s+/, $line;		      # generate a list of msg nos
my @out;

return (1, $self->msg('e5')) if $self->priv < 1;

if (@list == 0) {
	my $ref;
	push @out, "Work Queue Keys";
	push @out, map { " $_" } sort (DXMsg::get_all_fwq());
	push @out, "Busy Queue Data";
	foreach my $key (sort (DXMsg::get_all_busy())) {
		$ref = DXMsg::get_busy($key);
		if ($ref) {
			my $msgno = $ref->msgno;
			my $stream = $ref->stream;
			my $lref = $ref->lines;
			my $lines = 0;
			$lines = @$lref if $lref;
			my $count = $ref->count;
			my $to = $ref->to;
			my $from = $ref->from;
			my $tonode = $ref->tonode;
			my $lastt = $ref->lastt ? " Last Processed: " . cldatetime($ref->lastt) : "";
			my $waitt = $ref->waitt ? " Waiting since: " . cldatetime($ref->waitt) : "";
			push @out, " $key/$tonode: $from -> $to msg: $msgno stream: $stream Count: $count Lines: $lines$lastt$waitt"
		} else {
			push @out, " dangling ref for $key";
		}
	}
} else {
	foreach my $msgno (@list) {
		my $ref = DXMsg::get($msgno);
		if ($ref) {
			@out = print_all_fields($self, $ref, "Msg Parameters $msgno");
		} else {
			push @out, $self->msg('m4', $msgno);
		}
		push @out, "" if @list > 1;
	}
}

return (1, @out);
