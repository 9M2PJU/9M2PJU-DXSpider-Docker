#
# set the prompt of the user
#
# Copyright (c) 2001 - Dirk Koopman
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

# remove leading and trailing spaces
$line =~ s/^\s+//;
$line =~ s/\s+$//;

return (1, $self->msg('e9')) if !$line;

$user = DXUser::get_current($call);
if ($user) {
	$user->prompt($line);
	$self->{prompt} = $line;    # this is like this because $self->prompt is a function that does something else
	$user->put();
	return (1, $self->msg('prs', $line));
} else {
	return (1, $self->msg('namee2', $call));
}

