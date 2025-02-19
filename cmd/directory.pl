#
# show the contents of the message directory
#
# Copyright (c) Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;
my @ref;
my $ref;
my @out;
my $f;
my $n = 0;

# select candidates
my @all = grep {!$_->private || !($self->priv < 5 && $_->to ne $self->call && $_->from ne $self->call)} (DXMsg::get_all());
@all =  grep {!$_->delete  || ($self->priv >= 5 && $_->delete)} @all;

return (1, $self->msg('dir1')) unless @all;
my $sel = 0;
my $from = 0;
my $to = $all[@all-1]->msgno;

while (@f) {
	$f = uc shift @f;
	if ($f eq 'ALL') {
		@ref = @all;
		$n = @ref;
		$sel++;
	} elsif ($f =~ /^O/o) {		# dir/own
		@ref = grep { $_->to eq $self->call || $_->from eq $self->call } @all;
		$sel++;
	} elsif ($f =~ /^N/o) {		# dir/new
		@ref = grep { $_->t > $self->user->lastin } @all;
		$sel++;
	} elsif ($f =~ /^S/o) {     # dir/subject
		$f = shift @f;
		if ($f) {
			$f =~ s{(.)}{"\Q$1"}ge;
			@ref = grep { $_->subject =~ m{$f}i } @all;
			$sel++;
		}
	} elsif ($f eq '>' || $f =~ /^T/o){  
		$f = uc shift @f;
		if ($f) {
			$f = shellregex($f);
			@ref = grep { $_->to =~ m{$f} } @all;
			$sel++;
		}
	} elsif ($f eq '<' || $f =~ /^F/o){
		$f = uc shift @f;
		if ($f) {
			$f = shellregex($f);
			@ref = grep { $_->from =~ m{$f} } @all;
			$sel++;
		}
	} elsif ($f =~ /^(\d+)-(\d+)$/) {		# a range of items
		$from = $1;
		$to = $2;
	} elsif ($f =~ /^\d+$/ && $f > 0) {		# a number of items
		$n = $f;
	}
}

$n = 10 unless $n;
@ref = @all unless $sel || @ref;

if (@ref) {
	if ($from != 0 || $to != $all[@all-1]->msgno) {
		@ref = grep {$_->msgno >= $from && $_->msgno <= $to} @ref;
	}
	my $i = @ref - $n;
	$i = 0 unless $i > 0;
	my $count;
	while ($i < @ref) {
		$ref = $ref[$i++];
		push @out, $ref->dir;
		last if ++$count >= $n;
	}
} else {
	push @out, $self->msg('dir1'); 
}
return (1, @out);
