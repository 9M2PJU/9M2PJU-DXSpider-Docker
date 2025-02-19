#
# set any variable in the User file
#
# This is a hack - use the UTMOST CAUTION!!!!!!!!
#
# Copyright (c) 1999 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;

my @args = split /\s+/, $line;
return (1, $self->msg('suser1')) if @args < 3;


my $call = uc $args[0];
my $ref = DXUser::get_current($call);
my $field = $args[1];
my $value = $args[2];

return (1, $self->msg('suser2', $call)) unless $ref;
return (1, $self->msg('suser4', $field)) unless $ref->field_prompt($field);
my @out;

# set it (dates and silly things like that can come later)

if ($self->priv < 9 || $self->remotecmd || $self->inscript) {
	Log('DXCommand', $self->call . " attempted to set user var $field=$value on $call remotely");
	push @out, $self->msg('sorry');
}

my $oldvalue = $ref->{$field};
$ref->{$field} = $value;
$ref->put();

push @out, $self->msg('suser3', $field, $oldvalue, $value);
push  @out, print_all_fields($self, $ref, "User Information $call");

return (1, @out);
