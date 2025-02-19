#
# set the user's language
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
my $call = $self->call;
my $user;

# modify this next line if you add a language to Messages
my @lang = qw( en nl es de it cz pt fr );

# remove leading and trailing spaces
$line =~ s/^\s+//;
$line =~ s/\s+$//;

return (1, $self->msg('lange1', join(',', @lang))) if !$line;
$line = lc $line;
return (1, $self->msg('lange1', join(',', @lang))) unless grep $_ eq $line, @lang;


$user = DXUser::get_current($call);
if ($user) {
	$user->lang($line);
	$user->put();
	$self->lang($line);
	return (1, $self->msg('lang', $line));
} else {
	return (1, $self->msg('lange2', $call));
}

