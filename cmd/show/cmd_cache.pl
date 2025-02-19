#
# show the contents and paths of any commands in the cmd_cache
#
# This will tell you whether you are using the version of the command
# that you think you are...
#
# Copyright (c) 2007 Dirk Koopman G1TLH
#

my $self = shift;
my $line = shift;
return (1, $self->msg('e5')) if $self->priv < 9;

my @out = sprintf "%-20s %s", "Command", "Path";
for (sort keys %cmd_cache) {
	next if $line && $_ !~ m|\Q$line|i;
	my $v = $cmd_cache{$_};
	$v =~ s|,|/|g;
	push @out, sprintf "%-20s %s", $_, "$v.pl";
}

return (1, @out);
