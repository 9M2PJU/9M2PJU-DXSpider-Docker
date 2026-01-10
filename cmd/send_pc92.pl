#
# send out PC92 config records manually
#
# Send Update & Keepalive  (PC92 C and K)
#
# Modify by Kin EA3CV, ea3cv@cronux.net
#
# Copy in /spider/local_cmd/send_pc92.pl
# In the spider crontab you can add the following:
# 00,05,10,15,20,25,30,35,40,45,50,55 * * * * run_cmd('send_pc92')
#
# Note
# If you have few users, say <20, you can uncomment PC92C.
# If you have many users, it is better to leave the PC92C line commented out. 
#
# 20241005 v0.1
#

my $self = shift;
return (1, $self->msg('e5')) unless $self->priv > 5;

# Send PC92C
#$main::me->broadcast_pc92_update($main::mycall);
# Send PC92K
$main::me->broadcast_pc92_keepalive($main::mycall);

return (1, $self->msg('ok'));
