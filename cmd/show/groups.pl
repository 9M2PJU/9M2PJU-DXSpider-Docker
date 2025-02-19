#
# show recently used groups
#
# by Tommy SM3OSM
#
#
#

use Time::Local;
my $self = shift;
my $to = shift;

if ($to =~ /\D/) {
    return (1, "try sh/chatgroups xxx where xxx is the number of chat messages to search.");
}

my @out;
my $g= {};

$to = 500 unless $to;

my @chatlog = DXLog::print(undef, $to, $main::systime, 'chat', undef);
my $row;
my ($time, $call, $group);
my $found;
my %month = (
			 Jan => 0,
			 Feb => 1,
			 Mar => 2,
			 Apr => 3,
			 May => 4,
			 Jun => 5,
			 Jul => 6,
			 Aug => 7,
			 Sep => 8,
			 Oct => 9,
			 Nov => 10,
			 Dec => 11,
			);

@chatlog = reverse @chatlog;
foreach $row(@chatlog) {
    ($time, $call, $group) = ($row =~ m/^(\S+) (\S+) -> (\S+) /o);
    if (!exists $g->{$group}) {
		$time =~ m/^(\d\d)(\w{3})(\d{4})\@(\d\d):(\d\d):(\d\d)/o;
		$g->{$group}->{sec} = timegm($6, $5, $4, $1, $month{$2}, $3-1900);
		$time =~ s/\@/ at /;
		$g->{$group}->{last} = $time;
		push @{ $g->{$group}->{calls} }, $call;
    } else {
		$found = 0;
		foreach (@{ $g->{$group}->{calls} }) {
			if (/$call/) {
				$found = 1;
				last;
			}
		}
		push @{ $g->{$group}->{calls} }, $call unless $found;
    }
    $g->{$group}->{msgcount}++;
}

push (@out, "Chat groups recently used:");
push (@out, "($to messages searched)");
push (@out, "--------------------------");
my @calls;
my @l;
my $max = 6;
my $mtext;
foreach $group (sort { $g->{$b}->{sec}  <=> $g->{$a}->{sec} } keys %$g) {
    @calls = sort( @{ $g->{$group}->{calls} } );
    $mtext = "  " . $g->{$group}->{msgcount} . " messages by:";
    push (@out, "$group: Last active " . $g->{$group}->{last});
    if (@calls <= $max) {
		push (@out, "$mtext @calls");
    } else {
		foreach $call(@calls) {
			push @l, $call;
			if (@l >= $max) {
				if ($max == 6) {
					push (@out, "$mtext @l");
				} else {
					push (@out, "  @l");
				}
				@l = ();
				$max = 8;
			}
		}
		push (@out, "  @l") if (@l);
		$max = 6;
		@l = ();
    }
    push (@out, "-");
}
return (1, @out);
