#
# show either the current user or a nominated set
#
#
#

my ($self, $line) = @_;
my @list = split /\s+/, $line;	# generate a list of callsigns
@list = ($self->call) if !@list; # my channel if no callsigns

my $call;
my @out;
foreach $call (@list) {
	$call = uc $call;
	my $ref = DXUser::get_current($call);
	if ($ref) {
		if ($self->consort eq 'ax25') {
			@out = grep { !/(Password|Privilege)/ } print_all_fields($self, $ref, "User Information $call");
		} else {
			@out = print_all_fields($self, $ref, "User Information $call");
		}
	} else {
		push @out, "User: $call not found";
	}
	push @out, "" if @list > 1;
}

return (1, @out);
