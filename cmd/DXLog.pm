#
# the general purpose logging machine
#
# This module is designed to allow you to log stuff in specific places
# and will rotate logs on a monthly, weekly or daily basis. 
#
# The idea is that you give it a prefix which is a directory and then 
# the system will log stuff to a directory structure which looks like:-
#
# daily:-
#   spots/1998/<julian day no>[.<optional suffix>]
#
# weekly :-
#   log/1998/<week no>[.<optional suffix>]
#
# monthly
#   wwv/1998/<month>[.<optional suffix>]
#
# Routines are provided to read these files in and to append to them
# 
# Copyright (c) - 1998 Dirk Koopman G1TLH
#
#
# Modify by Kin EA3CV
#
# 20230304 v0.2
#

package DXLog;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Log LogDbg Logclose);

use IO::File;
use DXVars;
use DXUtil;
use Julian;

use Carp;

use strict;

use vars qw($log %logs);

$log = new('log', 'dat', 'm');

# create a log object that contains all the useful info needed
# prefix is the main directory off of the data directory
# sort is 'm' for monthly, 'd' for daily 
sub new
{
	my ($prefix, $suffix, $sort) = @_;
	my $ref = bless {}, __PACKAGE__;
	localdata_mv($prefix);
	$ref->{prefix} = "$main::local_data/$prefix";
	$ref->{suffix} = $suffix if $suffix;
	$ref->{sort} = $sort;
	
	# make sure the directory exists
	mkdir($ref->{prefix}, 0777) unless -e $ref->{prefix};
	$logs{$ref} = $ref;
	
	return $ref;
}

sub _genfn
{
	my ($self, $jdate) = @_;
	my $year = $jdate->year;
	my $thing = $jdate->thing;
	
	my $fn = sprintf "$self->{prefix}/$year/%02d", $thing if $jdate->isa('Julian::Month');
	$fn = sprintf "$self->{prefix}/$year/%03d", $thing if $jdate->isa('Julian::Day');
	$fn .= ".$self->{suffix}" if $self->{suffix};
	return $fn;
}

# open the appropriate data file
sub open
{
	my ($self, $jdate, $mode) = @_;
	
	# if we are writing, check that the directory exists
	if (defined $mode) {
		my $year = $jdate->year;
		my $dir = "$self->{prefix}/$year";
		mkdir($dir, 0777) if ! -e $dir;
	}

	$self->{fn} = $self->_genfn($jdate);
	
	$mode = 'r' if !$mode;
	$self->{mode} = $mode;
	$self->{jdate} = $jdate;
	
	my $fh = new IO::File $self->{fn}, $mode, 0666;
	return undef if !$fh;
	$fh->autoflush(0);			# autofluahing off
	$self->{fh} = $fh;

#	print "opening $self->{fn}\n";
	
	return $self->{fh};
}

sub fn
{
	my ($self, $jdate) = @_;
	
	return $self->_genfn($jdate);
}

sub delete($$)
{
	my ($self, $jdate) = @_;
	my $fn = $self->_genfn($jdate);
	unlink $fn;
}

sub mtime($$)
{
	my ($self, $jdate) = @_;
	
	my $fn = $self->_genfn($jdate);
	return (stat $fn)[9];
}

# open the previous log file in sequence
sub openprev($$)
{
	my $self = shift;
	my $jdate = $self->{jdate}->sub(1);
	return $self->open($jdate, @_);
}

# open the next log file in sequence
sub opennext($$)
{
	my $self = shift;
	my $jdate = $self->{jdate}->add(1);
	return $self->open($jdate, @_);
}

# convert a date into the correct format from a unix date depending on its sort
sub unixtoj($$)
{
	my $self = shift;
	
	if ($self->{'sort'} eq 'm') {
		return Julian::Month->new(shift);
	} elsif ($self->{'sort'} eq 'd') {
		return Julian::Day->new(shift);
	}
	confess "shouldn't get here";
}

# write (actually append) to a file, opening new files as required
sub write($$$)
{
	my ($self, $jdate, $line) = @_;
	return unless $self && $jdate;
	if (!$self->{fh} || 
		$self->{mode} ne ">>" || 
		$jdate->year != $self->{jdate}->year || 
		$jdate->thing != $self->{jdate}->thing) {
		$self->open($jdate, ">>") or confess "can't open $self->{fn} $!";
	}

	return $self->{fh}->print("$line\n");
}

# write (actually append) using the current date to a file, opening new files as required
sub writenow($$)
{
	my ($self, $line) = @_;
	my $t = time;
	my $date = $self->unixtoj($t);
	return $self->write($date, $line);
}

# write (actually append) using a unix time to a file, opening new files as required
sub writeunix($$$)
{
	my ($self, $t, $line) = @_;
	my $date = $self->unixtoj($t);
	return $self->write($date, $line);
}

# close the log file handle
sub close
{
	my $self = shift;
	undef $self->{fh};			# close the filehandle
	delete $self->{fh};	
}

sub DESTROY
{
	my $self = shift;
	delete $logs{$self};
	undef $self->{fh};			# close the filehandle
	delete $self->{fh} if $self->{fh};
}

sub flushall
{
	foreach my $l (values %logs) {
		$l->{fh}->flush if exists $l->{fh};
	}
}

# log something in the system log 
# this routine is exported to any module that declares DXLog
# it takes all its args and joins them together with the unixtime writes them out as one line
# The user is responsible for making sense of this!
sub Log
{
	my $t = time;
	$log->writeunix($t, join('^', $t, @_) );
# Kin
    if (defined &Local::log_msg) {
        my $self = 'Local';
            my $r;
            eval { $r = Local::log_msg($self, $t, join('^', $t, @_)); };
            return if $r;
    }
#
}

sub LogDbg
{
	my $cat = shift;
	DXDebug::dbg($_) for @_;
	Log($cat, @_);
}

sub Logclose
{
	$log->close();
}
1;
