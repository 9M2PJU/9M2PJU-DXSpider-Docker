#
# set the home mail bbs  of the user
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

return (1, $self->msg('bbse1')) if !$line;

$user = DXUser::get_current($call);
if ($user) {
	$line = uc $line;
	$user->bbs($line);
	$user->put();
	return (1, $self->msg('bbs', $line));
} else {
	return (1, $self->msg('namee2', $call));
}

