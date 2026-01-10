#
# List hashes of duplicates
#
# Usage: view_dupes <string>
#
# Copy to /spider/local_cmd
#
# Kin EA3CV
#
# 20250115 v0.0
#

use DXDupe;

my ($self, $string) = @_;

# For all
# DXDupe::get('X');

DXDupe::listdups('X',$Spot::dupage,$string);

