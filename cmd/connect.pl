#
# connect a cluster station
#
my $self = shift;
my $call = uc shift;
my $lccall = lc $call;

return (1, $self->msg('e5')) if $self->priv < 5;
return (1, $self->msg('e6')) unless $call gt ' ';
return (1, $self->msg('already', $call)) if DXChannel::get($call);
return (1, $self->msg('outconn', $call)) if grep {$_->{call} eq $call} @main::outstanding_connects;
return (1, $self->msg('conscript', $lccall)) unless -e "$main::root/connect/$lccall";

my $user = DXUser::get($call);
return (1, $self->msg('lockout', $call)) if $user && $user->lockout;

my @out;
push @out, $self->msg('constart', $call);
ExtMsg::start_connect($call, "$main::root/connect/$lccall");
return (1, @out);




