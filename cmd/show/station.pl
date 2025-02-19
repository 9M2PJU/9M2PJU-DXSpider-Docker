#
# show the station details
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
# Modifications by Iain Philipps G0RDI, 07-Dec-1998
#

my ($self, $line) = @_;
my @f = split /\s+/, uc $line;
my @out;
my $call;
my $seek;
push @f, $self->call unless @f;

if (@f <= 2 && uc $f[0] eq 'ALL') {
	return (1, $self->msg('e6')) if @f == 1 && $self->priv < 6; 
	return (1, $self->msg('e6')) if $self->priv < 5 || $f[1] eq '*'; 
	shift @f;
	my $exp = shellregex(uc shift @f) if @f; 
	my @calls;
	if ($exp) {
		@calls = grep {m{$exp}} DXUser::get_all_calls();
    } else {
		@calls = DXUser::get_all_calls();
	}
	
	foreach $call (@calls) {
		my $ref = DXUser::get_current($call);
		next if !$ref;
		my $lat = $ref->lat;
		my $long = $ref->long;
		my $sort = $ref->sort || "";
		my $name = $ref->name || "";
		my $qth = $ref->qth || "";
		my $homenode = $ref->homenode || "";
		my $qra = $ref->qra || "";
		my $latlong = DXBearing::lltos($lat, $long) if $lat && $long;
		$latlong = "" unless $latlong;
		
		push @out, sprintf "%-9s %s %-12.12s %-27.27s %-9s %s %s", $call, $sort, $name, $qth, $homenode, $latlong, $qra;
	}
} else {
	foreach $call (@f) {
		my $ref = DXUser::get_current($call);
		if ($ref) {
			my $name = $ref->name;  
			my $qth = $ref->qth;
			my $lat = $ref->lat;
			my $long = $ref->long;
			my $node = $ref->node;
			my $homenode = $ref->homenode;
			my $lastin = $ref->lastin;
			my $latlong = DXBearing::lltos($lat, $long) if $lat || $long;
			my $last = DXUtil::cldatetime($lastin) if $ref->lastin;
			my $qra = $ref->qra;
			$qra = DXBearing::lltoqra($lat, $long) if !$qra && ($lat || $long);
			my $from;
			my ($dx, $bearing, $miles);
			if ($latlong) {
				my ($hlat, $hlong) = ($self->user->lat, $self->user->long);
				($hlat, $hlong) = DXBearing::qratoll($self->user->qra) if $self->user->qra && !$hlat && !$hlong;
				if (!$hlat && !$hlong) {
					$from = "From $main::mycall";
					$hlat = $main::mylatitude;
					$hlong = $main::mylongitude;
				}
				($bearing, $dx) = DXBearing::bdist($hlat, $hlong, $lat, $long);
				$miles = $dx * 0.62133785;
			}
			
			my $cref = Route::get($call);
			my $seek = $cref->isa('Route::Node') ? $call : join(',', $cref->parents) if $cref;

			if ($seek) {
				push @out, sprintf("%-13s: %s (%s %s)", $self->msg('user'), $call, $self->msg('at'), $seek);
			} else {
				push @out, sprintf("%-13s: %s", $self->msg('user'), $call);
			}
			push @out, sprintf("%-13s: %s", $self->msg('name1'), $name) if $name;
			push @out, sprintf("%-13s: %s", $self->msg('lastconn'), $last) if $last;
			push @out, sprintf("%-13s: %s", 'QTH', $qth) if $qth;
			push @out, sprintf("%-13s: %s", $self->msg('location'), "$latlong ($qra)") if $latlong || $qra ;
			push @out, sprintf("%-13s: %.0f Deg. %.0f Mi. %.0f Km.", $self->msg('heading'), $bearing, $miles, $dx) if $latlong;
			push @out, sprintf("%-13s: %s", $self->msg('homenode2'), $homenode) if $homenode;
		} else {
			push @out, $self->msg('usernf', $call);
		}
	}
}

return (1, @out);
