#
# the bye command
#
#
#

my $self = shift;
return (1, $self->msg('e5')) if $self->inscript;

# log out text
if ($self->is_user && -e "$main::data/logout") {
	open(I, "$main::data/logout") or confess;
	my @in = <I>;
	close(I);
	$self->send_now('D', @in);
	sleep(1);
}

#$self->send_now('Z', "");

$self->disconnect;

return (1);
