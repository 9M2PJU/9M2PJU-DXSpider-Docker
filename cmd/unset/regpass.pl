#
# unset/regpass.pl — Unregister and remove password for a callsign
#
# Description:
#   This command performs both:
#     - unset/register <callsign>
#     - unset/password <callsign>
#   in a single unified operation.
#
# Usage:
#   From DXSpider shell:
#     unset/regpass <callsign>
#
# Location:
#   /spider/local_cmd/unset/regpass.pl
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

push @out, DXCommandmode::run_cmd($self, "unset/password $args[0]");
push @out, DXCommandmode::run_cmd($self, "unset/register $args[0]");

return (1, @out);
