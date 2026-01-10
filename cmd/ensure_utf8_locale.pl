#!/usr/bin/perl

#
# ensure_utf8_locale.pl — Ensure system effective locale uses UTF-8 (HOST ONLY)
#
# Behavior:
#   - Verifies effective encoding via `locale charmap`.
#   - If encoding is not UTF-8, enables <current_base>.UTF-8 (fallback C.UTF-8).
#   - Additionally (Debian-family): if effective UTF-8 is OK but C.UTF-8 is not present,
#     it will enable/generate C.UTF-8 (requires root) WITHOUT changing LANG.
#
# Not for containers: refuses to run in Docker/LXC/Podman.
#
# Exit codes:
#   0 OK
#   1 Unsupported/failed
#   2 Need root
#   3 Refused (container)
#
# Kin EA3CV <ea3cv@cronux.net>
# 2025-12-28 v0.6
#

use strict;
use warnings;

my $MODE = 'apply';
for my $a (@ARGV) {
    if ($a eq '--check') { $MODE = 'check'; }
    if ($a eq '--apply') { $MODE = 'apply'; }
    if ($a eq '--help' || $a eq '-h') {
        print <<"USAGE";
Usage:
  $0 --check
  sudo $0 --apply
  sudo $0            # default: apply

Host-only: refuses to run in containers.

USAGE
        exit 0;
    }
}

sub is_root { return ($> == 0) ? 1 : 0; }

sub slurp_first {
    my ($cmd) = @_;
    my $out = `$cmd 2>/dev/null`;
    $out = '' unless defined $out;
    $out =~ s/\r?\n\z//;
    return $out;
}

sub run {
    my ($cmd) = @_;
    print "[CMD] $cmd\n";
    system($cmd) == 0 or die "[ERROR] Command failed: $cmd\n";
}

sub detect_os_release {
    my %os;
    open my $fh, '<', '/etc/os-release' or die "[ERROR] Could not read /etc/os-release\n";
    while (<$fh>) {
        chomp;
        next if $_ eq '' || $_ =~ /^\s*#/;
        if (/^([A-Z0-9_]+)=(.*)$/) {
            my ($k, $v) = ($1, $2);
            $v =~ s/^"//; $v =~ s/"$//;
            $os{$k} = $v;
        }
    }
    close $fh;
    return \%os;
}

sub is_container {
    my $c = slurp_first('systemd-detect-virt -c');
    return 1 if $c && $c ne 'none';
    return 1 if -f '/.dockerenv';
    return 1 if -f '/run/.containerenv';
    my $cg = slurp_first(q{cat /proc/1/cgroup | head -n 80});
    return 1 if $cg =~ /(docker|kubepods|containerd|lxc|podman)/i;
    return 0;
}

sub current_lang {
    my $lang = slurp_first(q{locale 2>/dev/null | awk -F= '/^LANG=/{print $2; exit}'});
    $lang = $ENV{LANG} // '' if !$lang;
    $lang =~ s/\s+//g;
    return $lang || 'C';
}

sub current_charmap {
    my $cm = slurp_first('locale charmap');
    $cm =~ s/\s+//g;
    return $cm || '';
}

# Normalize locale name for comparison:
# - case-insensitive
# - treat UTF8 == UTF-8
# - keep dot/underscore as-is, but normalize "-"/none within UTF-8 suffix
sub norm_locale {
    my ($loc) = @_;
    $loc //= '';
    my $x = lc($loc);
    $x =~ s/\s+//g;
    $x =~ s/utf-8/utf8/g;
    return $x;
}

# Return (exists_bool, actual_name_if_found)
sub locale_exists {
    my ($wanted) = @_;
    return (0, '') if !$wanted;

    my $wanted_norm = norm_locale($wanted);

    my @list = `locale -a 2>/dev/null`;
    for my $l (@list) {
        $l =~ s/\r?\n\z//;
        next unless $l ne '';
        my $ln = norm_locale($l);

        # Exact normalized match
        if ($ln eq $wanted_norm) {
            return (1, $l);
        }

        # Special handling for C.UTF-8 aliases: accept C.utf8 / C.UTF8 / C.utf-8 etc.
        if ($wanted_norm eq 'c.utf8') {
            return (1, $l) if $ln eq 'c.utf8';
        }
        if ($wanted_norm eq 'c.utf-8') {
            return (1, $l) if $ln eq 'c.utf8';
        }
        if ($wanted_norm eq 'c.utf8') {
            return (1, $l) if $ln eq 'c.utf8';
        }

        # More general: if wanted is C.UTF-8, accept any c.utf8-ish
        if ($wanted_norm =~ /^c\.utf8$/) {
            return (1, $l) if $ln =~ /^c\.utf8$/;
        }
        if ($wanted_norm =~ /^c\.utf8$/) {
            return (1, $l) if $ln =~ /^c\.utf8$/;
        }
        if ($wanted_norm =~ /^c\.utf8$/) {
            return (1, $l) if $ln =~ /^c\.utf8$/;
        }
        if ($wanted_norm =~ /^c\.utf8$/) {
            return (1, $l) if $ln =~ /^c\.utf8$/;
        }

        # Simpler: if wanted is C.UTF-8 (normalized to c.utf8), accept c.utf8
        if ($wanted_norm eq 'c.utf8' && $ln eq 'c.utf8') {
            return (1, $l);
        }
    }

    return (0, '');
}

sub base_lang {
    my ($lang) = @_;
    $lang //= '';
    $lang =~ s/\s+//g;
    $lang =~ s/\..*$//;
    return $lang || 'C';
}

sub recommended_target_locale {
    my ($lang) = @_;
    my $base = base_lang($lang);
    if ($base eq 'C' || uc($base) eq 'POSIX') {
        return ('C.UTF-8', 'C');
    }
    return ("$base.UTF-8", $base);
}

sub deb_enable_and_generate_locale {
    my ($loc) = @_;

    my $gen = '/etc/locale.gen';
    run('DEBIAN_FRONTEND=noninteractive apt-get update -qq');
    run('DEBIAN_FRONTEND=noninteractive apt-get install -y -qq locales');

    my $has_line = system("grep -Eq '^[#[:space:]]*\\Q$loc\\E[[:space:]]+UTF-8\\s*\$' $gen") == 0 ? 1 : 0;
    if ($has_line) {
        run("sed -i -E 's/^[#[:space:]]*(\\Q$loc\\E[[:space:]]+UTF-8\\s*)\$/\\1/' $gen");
    } else {
        run("bash -c 'echo \"$loc UTF-8\" >> $gen'");
    }

    run('locale-gen');
}

sub report_c_utf8_availability {
    my ($ok, $name) = locale_exists('C.UTF-8');
    if ($ok) {
        print "[INFO] C.UTF-8 available: yes ($name)\n";
        return 1;
    } else {
        print "[INFO] C.UTF-8 available: no\n";
        return 0;
    }
}

# -------------------------
# Main
# -------------------------
if (is_container()) {
    print "[ERROR] Container detected. This script is HOST-ONLY and must not be used inside containers.\n";
    exit 3;
}

my $os  = detect_os_release();
my $id  = lc($os->{ID} // '');
my $ver = $os->{VERSION_ID} // '';
print "[INFO] Detected distribution: $id-$ver\n";

my $lang = current_lang();
my $cm   = current_charmap();
print "[INFO] Current LANG=$lang\n";
print "[INFO] Current charmap=$cm\n";

my $c_ok = report_c_utf8_availability();

# If UTF-8 is already effective, optionally ensure C.UTF-8 exists on Debian-family
if (uc($cm) eq 'UTF-8' || $lang =~ /\.UTF-8$/i) {
    print "[OK] Effective encoding is UTF-8\n";

    if (!$c_ok && $id =~ /^(debian|ubuntu|linuxmint|raspbian)$/) {
        if ($MODE eq 'check') {
            print "[WARN] C.UTF-8 is not available (check-only). Consider enabling it for service determinism.\n";
            exit 0;
        }
        if (!is_root()) {
            print "[WARN] C.UTF-8 is not available. To enable it, rerun as root.\n";
            exit 2;
        }

        print "[INFO] Enabling/generating C.UTF-8 (without changing LANG)...\n";
        deb_enable_and_generate_locale('C.UTF-8');

        my $c2 = report_c_utf8_availability();
        if (!$c2) {
            print "[WARN] locale-gen reported success but C.UTF-8 is still not listed by locale -a.\n";
            print "[WARN] Effective UTF-8 is OK. You may proceed, but inspect: /etc/locale.gen and `locale -a | grep -i c\\.utf`.\n";
            exit 0;
        }

        print "[DONE] C.UTF-8 is now available. (LANG unchanged: $lang)\n";
        exit 0;
    }

    exit 0;
}

# UTF-8 not active
if ($MODE eq 'check') {
    print "[WARN] UTF-8 is NOT active (check-only)\n";
    exit 1;
}
if (!is_root()) {
    print "[ERROR] UTF-8 is not active and changes are required. Run as root.\n";
    exit 2;
}

my ($target_locale, $base) = recommended_target_locale($lang);
my $fallback_locale = 'C.UTF-8';
print "[INFO] Desired locale: $target_locale (preserve base=$base)\n";

if ($id =~ /^(debian|ubuntu|linuxmint|raspbian)$/) {
    deb_enable_and_generate_locale($target_locale);

    my ($ok, $actual) = locale_exists($target_locale);
    if (!$ok) {
        print "[WARN] Locale not present after locale-gen: $target_locale. Falling back to $fallback_locale\n";
        deb_enable_and_generate_locale($fallback_locale);
        $target_locale = $fallback_locale;
    }

    run("update-locale LANG=$target_locale LC_CTYPE=$target_locale");

    my $cm2 = current_charmap();
    print "[INFO] Post-change charmap=$cm2\n";
    die "[ERROR] UTF-8 still not active after changes\n" if uc($cm2) ne 'UTF-8';

    print "[DONE] UTF-8 enabled: LANG=$target_locale LC_CTYPE=$target_locale\n";
    report_c_utf8_availability();
    exit 0;

} elsif ($id =~ /^(fedora|rhel|centos|rocky|almalinux)$/) {
    my $has_systemd = (-d '/run/systemd/system') ? 1 : 0;

    my ($ok, $actual) = locale_exists($target_locale);
    if (!$ok) {
        print "[WARN] Locale not present: $target_locale. Falling back to $fallback_locale\n";
        $target_locale = $fallback_locale;
    }

    if ($has_systemd) {
        run("localectl set-locale LANG=$target_locale");
        run("localectl set-locale LC_CTYPE=$target_locale");
    } else {
        open(my $fh, '>', '/etc/locale.conf') or die "[ERROR] Cannot write /etc/locale.conf: $!\n";
        print $fh "LANG=$target_locale\nLC_CTYPE=$target_locale\n";
        close $fh;
    }

    my $cm2 = current_charmap();
    print "[INFO] Post-change charmap=$cm2\n";
    die "[ERROR] UTF-8 still not active after changes\n" if uc($cm2) ne 'UTF-8';

    print "[DONE] UTF-8 enabled: LANG=$target_locale LC_CTYPE=$target_locale\n";
    report_c_utf8_availability();
    exit 0;

} else {
    print "[ERROR] Unsupported distribution ID='$id'. Configure UTF-8 manually.\n";
    exit 1;
}
