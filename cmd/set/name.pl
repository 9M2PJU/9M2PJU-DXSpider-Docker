#
# set the name of the user
#
# Copyright (c) 1998 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

# remove leading and trailing spaces
$line =~ s/^\s+//;
$line =~ s/\s+$//;
$line =~ s/[{}]//g;   # no braces allowed

return (1, $self->msg('namee1')) if !$line;

$user = DXUser::get_current($call);
if ($user) {
	$user->name($line);
	$user->put();
	my $s = DXProt::pc41($call, 1, $line);
	DXProt::eph_dup($s);
	DXChannel::broadcast_all_nodes($s, $main::me) ;
	return (1, $self->msg('name', $line));
} else {
	return (1, $self->msg('namee2', $call));
}

