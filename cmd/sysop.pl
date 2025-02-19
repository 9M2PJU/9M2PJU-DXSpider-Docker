#
# the sysop command for allowing people who have privileges that
# are denied them by connecting remotely
#
# Copyright (c) 1999 Dirk Koopman
#

my ($self, $line) = @_;
my $user = DXUser::get_current($self->call);
my $passwd = $user->passwd if $user;
my $lth = length $passwd;
$lth = 100 unless $lth;
my ($i, $r);
my @out;
my @list;

for ($i = 0; $i < 5; ++$i) {
	push @list, int rand($lth);
}

$self->passwd(\@list);
$self->state('sysop');
push @out, join(' ', @list);
return (1, @out);
