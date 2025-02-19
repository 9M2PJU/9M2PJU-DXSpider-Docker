#
# the show/files command, list bulls, files and areas 
#
# The equivalent of LS in other words
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my $root = "$main::root/packclus";
my @out;
my @file;
my @d;
my @slot;
my $patt = '^.*$';

if (@f) {
	my $fn = lc $f[0];
	$fn =~ s/\\/\//og;
	$fn =~ s/\.//og;
	$fn =~ s/^\///og;
	$root = "$root/$fn";

    $patt = shellregex(lc $f[1]) if defined $f[1];
}

opendir(DIR, $root) or 	return (1, $self->msg('e3', 'show/files', $f[0]));
@file = sort readdir(DIR);
closedir(DIR);

my $flag = 0;
for (@file) {
	next if /^\./;
    next unless m{$patt};
	my $fn = "$root/$_";
	my $size;
	
	@d = stat($fn);
	if (-d $fn) {
		$size = "DIR";
	} else {
		$size = $d[7]
	}
	$slot[$flag] = sprintf("%-10.10s %7.7s %s", $_, $size, cldatetime($d[9]));
	$flag ^= 1;
	if ($flag == 0 && @slot >= 2) {
		push @out, "$slot[0] $slot[1]";
	}
}
push @out, $slot[0] if $flag;
return (1, @out);


