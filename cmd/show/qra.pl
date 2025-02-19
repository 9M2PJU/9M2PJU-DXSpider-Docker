#
# show the distance and bearing to a  QRA locator
#
# you can enter two qra locators and it will calc the distance between them
#
#
#

my ($self, $line) = @_;
my @list = split /\s+/, $line;		      # generate a list of callsigns
return (1, $self->msg('qrashe1')) unless @list > 0;

my @out;

# every thing is dealt with in upper case
$line = uc $line;

# convert a lat/long into a qra locator if we see a pattern looking like a lat/long
if (is_latlong($line)) {
	my ($llat, $llong) = DXBearing::stoll(uc $line);
	return (1, "QRA $line = " . DXBearing::lltoqra($llat, $llong)); 
}

# get the user's lat/long else the cluster's (and whinge about it)
my $lat = $self->user->lat;
my $long = $self->user->long;
if (!$long && !$lat) {
	push @out, $self->msg('heade1');
	$lat = $main::mylatitude;
	$long = $main::mylongitude;
}

unshift @list, $self->user->qra if @list == 1 && $self->user->qra;
unshift @list, DXBearing::lltoqra($lat, $long) unless @list > 1;

# check from qra
my $f = uc $list[0];
$f .= 'MM' if $f =~ /^[A-Z][A-Z]\d\d$/;
return (1, $self->msg('qrae2', $f)) unless is_qra($f);
($lat, $long) = DXBearing::qratoll($f);

# check to qra
my $l = uc $list[1];
$l .= 'MM' if $l =~ /^[A-Z][A-Z]\d\d$/;
return (1, $self->msg('qrae2', $l)) unless is_qra($l);
my ($qlat, $qlong) = DXBearing::qratoll($l);

# generate alpha lat/long
my $fll = DXBearing::lltos($lat, $long);
$fll =~ s/\s+([NSEW])/$1/g;
my $tll = DXBearing::lltos($qlat, $qlong);
$tll =~ s/\s+([NSEW])/$1/g;

# calc bearings and distances 
my ($b, $dx) = DXBearing::bdist($lat, $long, $qlat, $qlong);
my ($r, $rdx) = DXBearing::bdist($qlat, $qlong, $lat, $long);
my $to = '';

$to = "->\U$list[1]($tll)" if $f;
my $from = "\U$list[0]($fll)" ;

push @out, sprintf "$from$to To: %.0f Fr: %.0f Dst: %.0fMi %.0fKm", $b, $r, $dx * 0.62133785, $dx;

return (1, @out);

