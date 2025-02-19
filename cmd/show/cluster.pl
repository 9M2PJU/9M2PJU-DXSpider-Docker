#
# show some statistics
#

my $self = shift;

my ($nodes, $tot, $users, $maxlocalusers, $maxusers, $uptime, $localnodes) = Route::cluster();

$localnodes = $main::routeroot->nodes;
$users = $main::routeroot->users;
$uptime = difft($main::starttime, ' ');

return (1, $self->msg('cluster', $localnodes, $nodes, $users, $tot, $maxlocalusers, $maxusers, $uptime));
