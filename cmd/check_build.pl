#!/usr/bin/perl

#
# Check if there is a new build.
# Setting 'Y' will backup to /home/sysop/spider.backup
# And the number of backups you want to save
#
# Only for the Mojo branch
#
# You need to install the rsync package
# apt install rsync
#
# Include the following line in the crontab:
# 0 4 * * 1,2,3,4,5 run_cmd("check_build <Y/N> <num_backups>")
#
# If you want to keep the check_build.pl tool up to date tool,
# add the following to your dxspider crontab (Thanks for the idea Keith G6NHU):
# 30 0 * * * spawn('cd /spider/local_cmd; wget -q https://raw.githubusercontent.com/EA3CV/dxspider_info/main/check_build.pl -O /spider/local_cmd/check_build.pl')
# 32 0 * * * run_cmd('load/cmd')
#
# Kin EA3CV, ea3cv@cronux.net
#
# 20250130 v1.15
#

use DXDebug;
use strict;
use warnings;

my ($self, $line) = @_;
my @args = split /\s+/, $line;

my $bckup = $args[0];
my $max_copies = ($args[1] - 1) // 10; # Default 10 copies

return 1 unless $self->{priv} >= 9;

my @out;
my $res;


# Change the working directory to /spider
chdir "$main::root";
push @out, "Verifying ...";

system('git remote update');

my $local_repo = `git rev-parse \@`;
my $remote_repo = `git rev-parse \@{u}`;

if ($local_repo ne $remote_repo) {
        $res = "There is a new build";
        dbg('DXCron::spawn: $res') if isdbg('cron');
        push @out, $res;

        if ($bckup =~ /Y/i) {
                $res = "Backup begins ...";
                push @out, $res;
                my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
                $year += 1900;
                $mon++;
                my $date = sprintf('%04d%02d%02d.%02d%02d%02d', $year, $mon, $mday, $hour, $min, $sec);
                my $backup_dir = "../spider.backup";
                unless (-d $backup_dir) {
                mkdir $backup_dir;
                }

                my $load = "*$self->{mycall}*   💾  *Backup Starts*";
                is_tg($load);

                my @exclude = qw(
                        --exclude=local_data/debug
                        --exclude=local_data/log
                        --exclude=local_data/spots
                        --exclude=local_data/wwv
                        --exclude=local_data/wcy
                );

                system("rsync", "-avh", @exclude, '.', "../spider.backup/$date");
                chdir "../spider.backup/";

                # Delete oldest backups if the maximum limit is exceeded
                my @backup_files = sort grep { /^spider\.\d{8}\.\d{6}\.tar\.gz$/ } glob("*");

                if (scalar @backup_files > $max_copies) {
                        my $num_files_to_delete = (scalar @backup_files) - $max_copies;

                        for (1..$num_files_to_delete) {
                                my $backup_file = shift @backup_files;
                                unlink $backup_file;
                        }
                }

                system("tar", "-czvf", "spider.$date.tar.gz", "--remove-files", "$date/");
                $res = "Backup completed.";
                push @out, $res;
                $load = "*$self->{mycall}*   🆗  *Backup Completed*";
                is_tg($load);
        }

        chdir "$main::root";
        # Reset and update the Git repository
        system('git reset --hard origin/mojo') == 0 or die push @out,"Failed to reset Git repository: $!";
        system('git pull') == 0 or die push @out,"Failed to pull updates from Git repository: $!";
        DXCron::run_cmd('shut');

} elsif ($local_repo eq $remote_repo) {
        $res = "There is no new build";
        push @out, $res;
        dbg('DXCron::spawn: $res') if isdbg('cron');
}

# Routine for sending a message via Telegram bot
# Needs to be enabled in Local.pm and DXVars.pm
sub is_tg
{
        my $msg = shift;

        if (defined &Local::telegram) {
                my $r;
                eval { $r = Local::telegram($msg); };
                return if $r;
        }
}

return (1, @out);
