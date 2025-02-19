#
# the export the user file to ascii command
#
#
#
my $self = shift;
my $line = shift || "$main::data/user_asc";
return (1, $self->msg('e5')) unless $self->priv >= 9;

my ($fn, $flag) = split /\s+/, $line;
return (1, DXUser::export($fn));
