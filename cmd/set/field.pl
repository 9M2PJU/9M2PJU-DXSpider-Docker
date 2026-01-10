#
#  set/field.pl — Set a specific field value for a user/node
#
#  Description:
#    This command updates a single user/node field, storing the new value via DXUser->put.
#    It is useful for modifying specific settings manually from the DXSpider console.
#    Compatible with both simple scalar fields and JSON-encoded array/hash values.
#
#  Usage:
#    From DXSpider shell:
#      set/field <CALLSIGN> <FIELD> <VALUE>
#
#  Location:
#    /spider/local_cmd/set/field.pl
#
#  Notes:
#    - Only for the Mojo branch of DXSpider
#    - Tested with DXUser.pm using the DB_Mysql.pm backend
#
#  Author  : Kin EA3CV <ea3cv@cronux.net>
#  Version : 20250625 v1.0
#

use strict;
use warnings;
use JSON;

my ($self, $line) = @_;
my ($call, $field, $value) = split(/\s+/, $line, 3);
my @out;

unless ($call && $field) {
    push @out, "Usage: set/field <CALL> <FIELD> <VALUE>";
    return (1, @out);
}

$call = uc $call;
my $ref = DXUser::get_current($call);
unless ($ref) {
    push @out, "User '$call' not found.";
    return (1, @out);
}

my %fields = map { $_ => 1 } $ref->fields;
unless ($fields{$field}) {
    push @out, "Field '$field' is not valid for this user.";
    return (1, @out);
}

# Attempt to decode JSON values for arrays/hashes
if ($value =~ /^\s*\[.*\]\s*$/ || $value =~ /^\s*\{.*\}\s*$/) {
    eval { $value = decode_json($value) };
    if ($@) {
        push @out, "Invalid JSON format: $@";
        return (1, @out);
    }
} elsif ($value =~ /^\d+$/) {
    $value += 0;
}

$ref->{$field} = $value;
if ($ref->put) {
    push @out, "Field '$field' for '$call' successfully updated.";
} else {
    push @out, "Failed to save changes.";
}

return (1, @out);
