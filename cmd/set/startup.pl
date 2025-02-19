#
# create or replace a startup script
#
# Copyright (c) 2005 Dirk Koopman G1TLH
#
#
#
my ($self, $line) = @_;
return (1, $self->msg('e5')) if $self->remotecmd || $self->inscript;
return (1, $self->msg('e5')) if $line && $self->priv < 6;
return (1, $self->msg('e36')) unless $self->state =~ /^prompt/;

my @out;
my $loc = $self->{loc} = { call => ($line || $self->call),
						   endaction => "store_startup_script",
						   lines => [],
						 };
# find me and set the state and the function on my state variable to
# keep calling me for every line until I relinquish control
$self->func("do_entry_stuff");
$self->state('enterbody');
push @out, $self->msg('m8');
return (1, @out);

