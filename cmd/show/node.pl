#
# show/node [<node> | <node> ] 
# 
# This command either lists all nodes known about 
# or the ones specified on the command line together
# with some information that is relavent to them 
#
# This command isn't and never will be compatible with AK1A
#
# A special millenium treat just for G4PDQ
#
# Copyright (c) 2000 Dirk Koopman G1TLH
#
#
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) unless $self->priv >= 1;
return (1, $self->msg('storable')) unless $DXUser::v3;

my @call = map {uc $_} split /\s+/, $line; 
my @out;
my $count;

# search thru the user for nodes
if (@call == 0) {
	@call = map {$_->call} DXChannel::get_all_nodes();
} elsif ($call[0] eq 'ALL') {
	shift @call;
	my ($action, $key, $data) = (0,0,0);
	for ($action = DXUser::R_FIRST, $count = 0; !$DXUser::dbm->seq($key, $data, $action); $action = DXUser::R_NEXT) {
		if ($data =~ m{\01[ACRSX]\0\0\0\04sort}) {
		    push @call, $key;
			++$count;
		}
	}
}

my $call;
foreach $call (sort @call) {
	my $clref = Route::Node::get($call);
	my $uref = DXUser::get_current($call);
	my ($sort, $ver, $build);
	
	my $pcall = sprintf "%-11s", $call;
	push @out, $self->msg('snode1') unless @out > 0;
	if ($uref) {
		$sort = "Spider" if $uref->is_spider || ($clref && $clref->do_pc9x);
		$sort = "Clx   " if $uref->is_clx;
		$sort = "User  " if $uref->is_user;
		$sort = "BBS   " if $uref->is_bbs;
		$sort = "DXNet " if $uref->is_dxnet;
		$sort = "ARClus" if $uref->is_arcluster;
		$sort = "AK1A  " if !$sort && $uref->is_ak1a;
		$sort = "Unknwn" unless $sort;
	} else {
		push @out, $self->msg('snode3', $call);
		next;
	}
	$ver = "";
	$build = "";
	if ($call eq $main::mycall) {
		$sort = "Spider";
		$ver = $main::version;
		$build = $main::build;
	} else {
		$ver = $clref->version if $clref && $clref->version;
		$ver = $uref->version if !$ver && $uref->version;
		$sort = "CCClus" if $ver && $ver >= 1000 && $ver < 4000 && $sort eq "Spider";
	}
	
	if ($uref->is_spider || ($clref && $clref->do_pc9x)) {
		if ($ver && $ver > 5400) {
			$ver =~ s/^5\d/5./;
		}
		if ($clref && $clref->build) {
			$build = $clref->build
		} elsif ($uref->build) {
			$build = $uref->build;
		}
		if ($build) {
			$build =~ s/^0\.//;
			$build = "build: $build";
		}
		push @out, $self->msg('snode2', $pcall, $sort, "$ver $build");
	} else {
		my ($major, $minor, $subs) = unpack("AAA*", $ver) if $ver;
		push @out, $self->msg('snode2', $pcall, $sort, $ver ? "$major\-$minor.$subs" : "      ");
	}
    ++$count;
}

return (1, @out, $self->msg('rec', $count));




