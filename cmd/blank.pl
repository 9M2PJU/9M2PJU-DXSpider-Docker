#
# Print n blank lines
#
# Copyright (c) 1998 Dirk Koopman G1TLH
#
#
#

sub this {};

sub that {};

sub another {}

sub handle
{
		my ($self, $line) = @_;
		my $lines = 1;
		my $data = ' ';
		my @f = split /\s+/, $line;
		if (@f && $f[0] !~ /^\d+$/) {
			$data = shift @f;
			$data = $data x int(($self->width-1) / length($data));
			$data .= substr $data, 0, int(($self->width-1) % length($data))
		}
		if (@f && $f[0] =~ /^\d+$/) {
			$lines = shift @f;
			$lines = 9 if $lines > 9;
			$lines = 1 if $lines < 1;
		}
		my @out;
		push @out, $data for (1..$lines);
		return (1, @out);
}
