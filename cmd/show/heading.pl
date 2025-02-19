#
# show the heading and distance for each callsign or prefix entered
#
#
#
# AK1A-compatible output Iain Philipps, G0RDI 16-Dec-1998
#
my ($self, $line) = @_;
my @list = split /\s+/, $line;                # generate a list of callsigns

my $l;
my @out;
my $lat = $self->user->lat;
my $long = $self->user->long;
if (!$long && !$lat) {
        push @out, $self->msg('heade1');
        $lat = $main::mylatitude;
        $long = $main::mylongitude;
}

foreach $l (@list) {
        # prefixes --->
        my @ans = Prefix::extract($l);
        next if !@ans;
        my $pre = shift @ans;
        my $a;
        foreach $a (@ans) {
                my ($b, $dx) = DXBearing::bdist($lat, $long, $a->{lat}, $a->{long});
                my ($r, $rdx) = DXBearing::bdist($a->{lat}, $a->{long}, $lat, $long);
                push @out, sprintf "%-2s %s: %.0f degs - dist: %.0f mi, %.0f km Reciprocal heading: %.0f degs", $pre, $a->name(), $b, $dx * 0.62133785, $dx, $r;
                $l = "";
        }
}

return (1, @out);
