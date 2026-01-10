#
#  show/list_pc92_nodes - Show nodes seen via PC92 (those with field K set)
#
#  Description:
#    Lists all DXSpider nodes that have the internal field "K" set to true (1),
#    meaning they have been seen using the PC92 protocol. It also allows querying
#    a specific node to check if it has the field set.
#
#  Usage:
#    show/list_pc92_nodes             → List all nodes with K = 1
#    show/list_pc92_nodes <CALL>      → Check if a specific node has K set
#
#  Notes:
#    This script should be installed in: /spider/local_cmd/show
#
#  Author:   Kin EA3CV <ea3cv@cronux.net>
#
#  Date:     20250404 v0.0
#

my ($self, $line) = @_;
my $call = uc($line // '');
return (1, $self->msg('e5')) if $self->priv < 6;

my @out;

if ($call) {
    return (1, $self->msg('e22', $call)) unless is_callsign($call);
    my $user = DXUser::get_current($call);
    return (1, $self->msg('e13', $call)) unless $user && $user->is_node;

    if ($user->K && $user->K == 1) {
        push @out, "$call: field K is set";
    } else {
        push @out, "$call: field K is not set";
    }
    return (1, @out);
}

# Si no se pasa indicativo, mostrar todos
my @calls = DXUser::get_all_calls;
my @matches;

foreach my $c (sort @calls) {
    my $u = DXUser::get_current($c);
    next unless $u && $u->is_node;

    if ($u->K && $u->K == 1) {
        push @matches, $c;
    }
}

push @out, "Nodes seen on PC92:";

if (@matches) {
    my @row;
    foreach my $c (@matches) {
        push @row, $c;
        if (@row == 5) {
            push @out, sprintf "%-14s %-14s %-14s %-14s %-14s", @row;
            @row = ();
        }
    }
    if (@row) {
        push @row, "" while @row < 5;
        push @out, sprintf "%-14s %-14s %-14s %-14s %-14s", @row;
    }
} else {
    push @out, "No nodes seen on PC92:";
}

return (1, @out);
