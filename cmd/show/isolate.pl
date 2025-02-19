#
# show/isolate
#
# show all excluded users 
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) unless $self->priv >= 1;

my @out;

use DB_File;

my ($action, $count, $key, $data) = (0,0,0,0);
for ($action = DXUser::R_FIRST, $count=0; !$DXUser::dbm->seq($key, $data, $action); $action = DXUser::R_NEXT) {
	if ($data =~ m{isolate}) {
		my $u = DXUser::get_current($key);
		if ($u && $u->isolate) {
			push @out, $key;
			++$count;
		}
	}
} 

return (1, @out, $self->msg('rec', $count));


