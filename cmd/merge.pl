#
# merge spot and wwv databases
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my @f = split /\s+/, $line;

# check for callsign
return (1, $self->msg('e5')) if $self->priv < 5;
return (1, $self->msg('e12')) if !$f[0];

my $call = uc $f[0];
return (1, $self->msg('e11', $call)) if $call eq $main::mycall;
	if ($call eq $main::mycall) {
		push @out, $self->msg('e11', $call);
		next;
	}

my $ref = Route::Node::get($call);
my $dxchan = $ref->dxchan if $ref;
return (1, $self->msg('e10', $call)) unless $ref;


my ($spots, $wwv) = $f[1] =~ m{(\d+)/(\d+)} if $f[1];
$spots = 10 unless $spots;
$wwv = 5 unless $wwv;

# I know, I know -  but is there any point?
$dxchan->send("PC25^$call^$main::mycall^$spots^$wwv^");

return (1, $self->msg('merge1', $call, $spots, $wwv));


