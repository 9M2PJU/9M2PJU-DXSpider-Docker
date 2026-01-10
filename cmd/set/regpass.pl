#
# set/regpass.pl — Register and set password for a callsign
#
# Description:
#   This command performs both:
#     - set/register <callsign>
#     - set/password <callsign> <password>
#   in a single unified operation.
#
# Usage:
#   From DXSpider shell:
#     set/regpass <callsign> <password>
#
# Location:
#   /spider/local_cmd/set/regpass.pl
#
# Notes:
#   - Only for the Mojo branch of DXSpider
#
# Author  : Kin EA3CV ea3cv@cronux.net
# Version : 20250406 v0.1
#


my ($self, $line) = @_;
my @args = split /\s+/, $line, 2;

my @out;

push @out, DXCommandmode::run_cmd($self, "set/register $args[0]");
push @out, DXCommandmode::run_cmd($self, "set/password $args[0] $args[1]");

return (1, @out);
