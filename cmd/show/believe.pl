# 
#  show/believe    
#                                                                      
#  Description:                                                         
#    Displays the list of nodes that a given node considers as "believable" 
#    using the 'believe' field from the user database.                
#                                                                        
#  Usage:                                                                
#    show/believe <node>       # Show believes for a specific node         
#    show/believe              # Show all nodes that have any believes set
#                                                                         
#  Notes:                                                                    
#    - Only nodes (not users) are considered                              
#    - If no believes are set, it will report (none)                         
#                                                                        
#  Author:   Kin EA3CV ea3cv@cronux.net                                                     
#
#  20250404 v0.0                                                       #
#                                                           

my ($self, $line) = @_;
my $node = uc $line;
my @out;

return (1, $self->msg('e5')) if $self->priv < 6;

if ($node) {
    return (1, $self->msg('e22', $node)) unless is_callsign($node);
    my $user = DXUser::get_current($node);
    return (1, $self->msg('e13', $node)) unless $user->is_node;

    my %seen;
    my @believes = grep { !$seen{$_}++ } $user->believe;

    if (@believes) {
        push @out, "$node: " . join(' ', sort @believes);
    } else {
        push @out, "$node: (none)";
    }
    return (1, @out);
}

# Mostrar todos los nodos con believes
my @calls = DXUser::get_all_calls;
my @lines;

foreach my $c (sort @calls) {
    my $u = DXUser::get_current($c);
    next unless $u && $u->is_node;

    my %seen;
    my @believes = grep { !$seen{$_}++ } $u->believe;
    next unless @believes;

    push @lines, "$c: " . join(' ', sort @believes);
}

push @out, @lines ? ("List of all believes set by nodes:", @lines)
                  : ("No nodes have any believes set.");

return (1, @out);

