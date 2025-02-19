#
# set any variable
#
# Rape me!
#
# Copyright (c) 1999 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 9 || $self->remotecmd;
return (1, $self->msg('e9')) unless $line;

my ($var, $rest) = split /=|\s+/, $line, 2;
$rest =~ s/^=\s*//;
Log('DXCommand', $self->call . " set $var = " . dd($rest) );
eval "$var = $rest";
return (1, $@ ? $@ : "Ok, $var = " . dd($rest) );



		
