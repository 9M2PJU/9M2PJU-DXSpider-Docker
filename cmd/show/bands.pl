#
# display the band data
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#

#DB::single = 1;

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @bands = grep {Bands::get($_)?$_:()} @f;
my @regs = grep {Bands::get_region($_)?$_:()} @f;
my $band;
my @out;
my $i;

unless (@f) {
	@bands = Bands::get_keys();
	@regs =  Bands::get_region_keys();
}
if (@bands) {
	@bands = sort { Bands::get($a)->band->[0] <=> Bands::get($b)->band->[0] } @bands;
	push @out, "Bands Available:-";
	foreach my $name (@bands) {
		my $band = Bands::get($name);
		my $ref = $band->band;
		my $s = sprintf "%10s: ", $name;
		for ($i = 0; $i < @$ref; $i += 2) {
			my $from = $ref->[$i];
			my $to = $ref->[$i+1];
			$s .= ", " if $i;
			$s .= "$from -> $to";
		}
		push @out, $s;
	}
}

if (@regs) {
	push @out, "Regions Available:-";
	@regs = sort @regs;
	foreach my $region (@regs) {
		my $ref = Bands::get_region($region);
		my $s = sprintf("%10s: ", $region ) . join(' ', @{$ref});
		push @out, $s;
	}
}

return (1, @out);
