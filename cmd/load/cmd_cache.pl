#
# reset/reload the short name command cache
#
# you may need to do this if you remove files or the system
# gets confused about where it should be loading its cmd files
# from.
#
# Copyright (c) 1998 - Dirk Koopman G1TLH
#
#
#
my $self = shift;
#$DB::single = 1;
return (1, $self->msg('e5')) if $self->priv < 9;
DXCommandmode::clear_cmd_cache();
return (1, $self->msg('ok'));
