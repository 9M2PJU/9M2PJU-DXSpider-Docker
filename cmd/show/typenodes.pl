#
# show/typenodes
#
# Description:
#   This command queries the node's internal user database to retrieve all
#   known nodes, grouped by their type (`sort` field) and sorted alphabetically.
#
#   Each node type appears under its own header
#
#   If a type letter is passed as argument (e.g. X, S, C), only that
#   group will be displayed.
#
# Supported node types:
#   S => DXSpider
#   A => AK1A
#   C => CLX
#   L => CC Cluster
#   X => DXNet
#
# Usage:
#   show/typenodes         # shows all types
#
#
# Author: Kin EA3CV, ea3cv@cronux.net
#
# 20250407 v0.1
#

my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->priv < 5;

my %labels = (
    'S' => 'DXSpider',
    'C' => 'CLX',
    'L' => 'CC Cluster',
    'A' => 'AK1A',
    'X' => 'DXNet',
);

my %nodes;

# Normalize input argument (type letter)
my $filter = uc($line // '');
$filter =~ s/[^SCLAX]//g;

# Gather nodes by type
foreach my $call (DXUser::get_all_calls()) {
    my $user = DXUser::get_current($call) or next;
    next unless $user->is_node;

    my $type = $user->sort || '';
    next if $type eq 'U';
    next if $filter && $type ne $filter;

    push @{ $nodes{$type} }, $call;
}

my @out;

# If a filter was passed but no valid nodes found, show message
if ($filter && !exists $nodes{$filter}) {
    push @out, "No nodes found for type '$filter'. Supported types: S, C, L, A, X.";
    return (1, @out);
}

# Choose which types to show: filtered or all
my @types = $filter ? ($filter) : qw(S C L A X);

foreach my $type (@types) {
    next unless exists $nodes{$type};

    my $label = $labels{$type} || "Unknown";

    push @out, "############################## Nodes $label ###############################";

    my @sorted = sort @{ $nodes{$type} };
    my @line;

    foreach my $c (@sorted) {
        push @line, sprintf "%-12s", $c;
        if (@line == 6) {
            push @out, join(' ', @line);
            @line = ();
        }
    }
    push @out, join(' ', @line) if @line;
    push @out, "";
}

return (1, @out);
