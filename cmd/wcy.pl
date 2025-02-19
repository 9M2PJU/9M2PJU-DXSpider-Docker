#
# WCY command
#
# This can only be used if the appropriate flag is enabled.
#
# I would STRONGLY recommend that, unless your callsign is DK8LV, you
# DO NOT ENABLE THIS COMMAND - YES THAT MEANS YOU!!!
#
# The command line sent from DK0WCY (the only known valid source of data
# for this command [and its only legitimate user BTW]):-
#
#    WCY k=6,expk=5,a=25,r=220,sf=202,sa=act,gmf=act,au=strong
#
#       k: Kiel k-Index  (0..9)
#    expK: expected Kiel k-index for the current 3-h-measuring period
#       A: Kiel A-Index (0..400)
#       R: Sunspot Number, SSN (0..300)
#      SF: Solar Flux Index (65..300)
#      SA: Sun Activity (qui,eru,act,maj,pro,war,nil)
#     GMF: Geomagnetic Field (qui,act,min,maj,sev,mag,war,nil)
#      AU: Aurora Status (no,aurora,strong)
#
# Copyright (c) 2001 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
my $call = $self->call;
$call =~ s/-\d+$//;
return (1, $self->msg('e5')) unless grep $call eq $_, @WCY::allowed;
my @out;

# calc 18 minutes past the hour in time_t seconds
my $hour = (gmtime $main::systime)[2];
my $d = int ($main::systime / 3600) * 3600 + 18 * 60; 

# make a hash out of the args
$line = unpad($line);
my %args = map {split /\s*=\s*/} split /\s*,\s*/, lc $line;

# check the ranges of each one
push @out, $self->msg('wcy1', 'k') unless defined $args{k} && $args{k} >= 0 && $args{k} <= 9;
push @out, $self->msg('wcy1', 'espk') unless defined $args{expk} && $args{expk} >= 0 && $args{expk} <= 9;
push @out, $self->msg('wcy1', 'a') unless defined $args{a} && $args{a} >= 0 && $args{a} <= 400;
push @out, $self->msg('wcy1', 'r') unless defined $args{r} && $args{r} >= 0 && $args{r} <= 500;
push @out, $self->msg('wcy1', 'sf') unless defined $args{sf} && $args{sf} >= 65 && $args{sf} <= 300;
push @out, $self->msg('wcy1', 'sa') unless defined $args{sa} && grep $args{sa} eq $_, qw(qui eru act maj pro war nil);
push @out, $self->msg('wcy1', 'gmf') unless defined $args{gmf} && grep $args{gmf} eq $_, qw(qui act min maj sev mag war nil);
push @out, $self->msg('wcy1', 'au') unless defined $args{au} && grep $args{au} eq $_, qw(no aurora strong);

push @out, $self->msg('wcy2') if WCY::dup($d);
#$DB::single=1;

return (1, @out) if @out;

# now this is all subject to change, but it will do for now, I think. 
my $today = cldate($main::systime);

# PC73^14-Dec-2001^15^220^  3^1^0^212^act^qui^no^DK0WCY-3^DB0SUE-7^H96^
# Date        Hour   SFI   A   K Exp.K   R SA    GMF   Aurora   Logger
# 14-Dec-2001   15   220   3   1     0 212 act   qui       no <DK0WCY-3>
my @field = ('PC73',$today,$hour,$args{sf},$args{a},$args{k},$args{expk},$args{r},$args{sa},$args{gmf},$args{au}, $self->call ,$main::mycall, 'H99');

my $s = sprintf "%s^%s^%02d^%3d^%3d^%2d^%2d^%3d^%s^%s^%s^%s^%s^%s^", @field;
WCY::update($d, @field[2..12]);
DXProt::send_wcy_spot($self, $s, $d, @field[2..12]);
$self->wcy($s, 0, @field[1..12]);
return (1, @out);


