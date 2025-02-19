#
# print out the general log file for talks only
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#
my $self = shift;

my $cmdline = shift;
my @f = split /\s+/, $cmdline;
my $f;
my @out;
my ($from, $to, $who); 

$from = 0;
while ($f = shift @f) {                 # next field
	#  print "f: $f list: ", join(',', @list), "\n";
	if (!$from && !$to) {
		($from, $to) = $f =~ /^(\d+)-(\d+)$/o;         # is it a from -> to count?
		next if $from && $to > $from;
	}
	if (!$to) {
		($to) = $f =~ /^(\d+)$/o if !$to;              # is it a to count?
		next if $to;
	}
	next if $who;
	($who) = $f =~ /^(\w+)/o;
}

$to = 20 unless $to;
$from = 0 unless $from;
if ($self->priv < 6) {
	$who = $self->call unless $who;
	return (1, $self->msg('e5')) if $who ne $self->call;
}

@out = DXLog::print($from, $to, $main::systime, 'talk', $who);
return (1, @out);
