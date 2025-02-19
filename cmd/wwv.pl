#
# WWV command
#
# This can only be used if the appropriate flag is enabled.
#
# I would STRONGLY recommend that you
# DO NOT ENABLE THIS COMMAND - YES THAT MEANS YOU!!!
#
# There are enough internet sources of WWV, you should really
# only enable a callsign for posting WWV spots if it is some
# RELIABLE automatic feed from somewhere.
#
# If you want to allow this command then you need to know that
# you must set/var @Geomag::allowed = qw(call call call) for EVERY
# callsign that issues wwv not just on your node but from outside 
# AS WELL. 
#
# I am making this deliberately hard because I believe that you are
# either a RELIABLE (probably machine generated) source of WWV or
# you shouldn't be doing it (and will have consequent problems).
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my $call = $self->call;
$call =~ s/-\d+$//;
return (1, $self->msg('e5')) unless grep $call eq $_, @Geomag::allowed;

my @out;

#$DB::single = 1;

# calc 18 minutes past the hour in time_t seconds
my $hour = (gmtime $main::systime)[2];
my $d = int ($main::systime / 3600) * 3600 + 18 * 60; 

$line = unpad($line);

my @l = split /\s*,\s*/, $line;
my $forecast = pop @l;

# make a hash out of the args
my %args = map {split /\s*=\s*/, lc $_} @l; 

# check the ranges of each one
push @out, $self->msg('wwv1', 'k') unless defined $args{k} && $args{k} >= 0 && $args{k} <= 9;
push @out, $self->msg('wwv1', 'a') unless defined $args{a} && $args{a} >= 0 && $args{a} <= 400;
push @out, $self->msg('wwv1', 'sf') unless defined $args{sf} && $args{sf} >= 65 && $args{sf} <= 300;
push @out, $self->msg('wwv1', 'forecast') unless $forecast;
push @out, $self->msg('wwv2') if Geomag::dup($d, $args{sf}, $args{k}, $args{a}, $forecast);

return (1, @out) if @out;

# now this is all subject to change, but it will do for now, I think. 
my $today = cldate($main::systime);


# PC23^14-Dec-2001^15^220^  4^ 1^R=212 SA:mo=>mo-hi GF:qu=>qu-un^KH2D^KH2D^H48^~
# Date        Hour   SFI   A   K Forecast                               Logger
# 14-Dec-2001   15   220   4   1 R=212 SA:mo=>mo-hi GF:qu=>qu-un       <KH2D>

my @field = ('PC23',$today,$hour,$args{sf},$args{a},$args{k},$forecast, $self->call ,$main::mycall, 'H99');

my $s = join('^', @field) . '^';
my ($r) = $forecast =~ /R=(\d+)/;
Geomag::update($d, @field[2..8], $r);
DXProt::send_wwv_spot($self, $s, $d, @field[2..8]);
#$self->wwv($s, 0, @field[1..8]);
return (1, @out);


