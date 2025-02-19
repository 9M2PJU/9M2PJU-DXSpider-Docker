#
# show all the values in a db fcb
#
#
#

my ($self, $line) = @_;
my @list = split /\s+/, $line;		      # generate a list of msg nos
my @out;

return (1, $self->msg('e5')) if $self->priv < 5;
return (1, $self->msg('m16')) if @list == 0;

foreach my $name (@list) {
  my $ref = DXDb::getdesc($name);
  if ($ref) {
    @out = print_all_fields($self, $ref, "DB Parameters $name");
  } else {
    push @out, $self->msg('db3', $name);
  }
  push @out, "" if @list > 1;
}

return (1, @out);
