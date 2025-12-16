#!/usr/bin/perl
#
# Notify::Filter - Filter engine for DXSpider notifications
#
# Provides filtering capabilities for spots based on:
# - Band (160m, 80m, 40m, 20m, 15m, 10m, 6m, 2m, 70cm)
# - Mode (CW, SSB, FT8, FT4, RTTY, etc.)
# - DXCC entity
# - Callsign patterns
# - Spotter patterns
# - Combination filters (AND/OR)
#
# Copyright (c) 2025 9M2PJU-DXSpider-Docker Project
#

package Notify::Filter;

use strict;
use warnings;
use DXDebug;

our $VERSION = '1.0.0';

#
# Create a new filter engine
#
sub new {
    my ($class, $config) = @_;

    my $self = {
        filters => $config || [],
    };

    bless $self, $class;
    return $self;
}

#
# Check if a spot matches the filter criteria
# Returns 1 if spot should be notified, 0 otherwise
#
sub matches {
    my ($self, $spot) = @_;

    # No filters = match everything
    return 1 unless @{$self->{filters}};

    # Apply filters with OR logic (any filter matches = notify)
    foreach my $filter (@{$self->{filters}}) {
        if ($self->apply_filter($spot, $filter)) {
            return 1;
        }
    }

    return 0;
}

#
# Apply a single filter to a spot
# Filters can be simple (one criterion) or compound (AND/OR)
#
sub apply_filter {
    my ($self, $spot, $filter) = @_;

    # Handle compound filters with explicit logic
    if (exists $filter->{and}) {
        return $self->apply_and($spot, $filter->{and});
    }
    if (exists $filter->{or}) {
        return $self->apply_or($spot, $filter->{or});
    }

    # Simple filter - apply all criteria with AND logic
    my $match = 1;

    # Band filter
    if (exists $filter->{bands}) {
        $match &&= $self->match_band($spot, $filter->{bands});
    }

    # Mode filter
    if (exists $filter->{modes}) {
        $match &&= $self->match_mode($spot, $filter->{modes});
    }

    # DXCC filter
    if (exists $filter->{dxcc}) {
        $match &&= $self->match_dxcc($spot, $filter->{dxcc});
    }

    # Callsign filter
    if (exists $filter->{callsign}) {
        $match &&= $self->match_callsign($spot, $filter->{callsign});
    }

    # Spotter filter
    if (exists $filter->{spotter}) {
        $match &&= $self->match_spotter($spot, $filter->{spotter});
    }

    # Frequency range filter
    if (exists $filter->{freq_min} || exists $filter->{freq_max}) {
        $match &&= $self->match_freq_range($spot, $filter->{freq_min}, $filter->{freq_max});
    }

    # Comment contains filter
    if (exists $filter->{comment_contains}) {
        $match &&= $self->match_comment($spot, $filter->{comment_contains});
    }

    return $match;
}

#
# Apply AND logic to multiple filters
#
sub apply_and {
    my ($self, $spot, $filters) = @_;

    foreach my $filter (@$filters) {
        return 0 unless $self->apply_filter($spot, $filter);
    }

    return 1;
}

#
# Apply OR logic to multiple filters
#
sub apply_or {
    my ($self, $spot, $filters) = @_;

    foreach my $filter (@$filters) {
        return 1 if $self->apply_filter($spot, $filter);
    }

    return 0;
}

#
# Match band
# Accepts array of band names or single string
#
sub match_band {
    my ($self, $spot, $bands) = @_;

    my @band_list = ref($bands) eq 'ARRAY' ? @$bands : ($bands);
    my $spot_band = $spot->{band} || '';

    foreach my $band (@band_list) {
        return 1 if lc($spot_band) eq lc($band);
    }

    return 0;
}

#
# Match mode
# Accepts array of mode names or single string
#
sub match_mode {
    my ($self, $spot, $modes) = @_;

    my @mode_list = ref($modes) eq 'ARRAY' ? @$modes : ($modes);
    my $spot_mode = $spot->{mode} || 'UNKNOWN';

    foreach my $mode (@mode_list) {
        return 1 if lc($spot_mode) eq lc($mode);
    }

    return 0;
}

#
# Match DXCC entity
# Requires Prefix module from DXSpider
#
sub match_dxcc {
    my ($self, $spot, $dxcc_filter) = @_;

    # Load Prefix module if available
    eval { require Prefix; };
    if ($@) {
        LogDbg('notify', "Prefix module not available for DXCC filtering");
        return 1; # Pass through if we can't check
    }

    my @dxcc_list = ref($dxcc_filter) eq 'ARRAY' ? @$dxcc_filter : ($dxcc_filter);

    # Get DXCC for spotted call
    my ($dxcc, undef) = Prefix::extract($spot->{call});

    if ($dxcc) {
        foreach my $wanted (@dxcc_list) {
            # Support both DXCC number and prefix
            if ($wanted =~ /^\d+$/) {
                return 1 if $dxcc == $wanted;
            } else {
                my ($wanted_dxcc, undef) = Prefix::extract($wanted);
                return 1 if $dxcc == $wanted_dxcc;
            }
        }
    }

    return 0;
}

#
# Match callsign pattern
# Supports regex patterns
#
sub match_callsign {
    my ($self, $spot, $pattern) = @_;

    my @patterns = ref($pattern) eq 'ARRAY' ? @$pattern : ($pattern);
    my $call = $spot->{call} || '';

    foreach my $pat (@patterns) {
        # Convert wildcard to regex if needed
        $pat =~ s/\*/\.\*/g;
        $pat =~ s/\?/\./g;

        return 1 if $call =~ /$pat/i;
    }

    return 0;
}

#
# Match spotter pattern
# Supports regex patterns
#
sub match_spotter {
    my ($self, $spot, $pattern) = @_;

    my @patterns = ref($pattern) eq 'ARRAY' ? @$pattern : ($pattern);
    my $spotter = $spot->{spotter} || '';

    foreach my $pat (@patterns) {
        # Convert wildcard to regex if needed
        $pat =~ s/\*/\.\*/g;
        $pat =~ s/\?/\./g;

        return 1 if $spotter =~ /$pat/i;
    }

    return 0;
}

#
# Match frequency range
#
sub match_freq_range {
    my ($self, $spot, $min, $max) = @_;

    my $freq = $spot->{freq} || 0;

    if (defined $min && $freq < $min) {
        return 0;
    }

    if (defined $max && $freq > $max) {
        return 0;
    }

    return 1;
}

#
# Match comment content
#
sub match_comment {
    my ($self, $spot, $pattern) = @_;

    my @patterns = ref($pattern) eq 'ARRAY' ? @$pattern : ($pattern);
    my $comment = $spot->{comment} || '';

    foreach my $pat (@patterns) {
        return 1 if $comment =~ /$pat/i;
    }

    return 0;
}

1;

__END__

=head1 NAME

Notify::Filter - Filter engine for DXSpider spot notifications

=head1 SYNOPSIS

  use Notify::Filter;

  my $filter = Notify::Filter->new([
    { bands => ['20m', '15m'] },
    { modes => ['FT8', 'CW'] },
  ]);

  if ($filter->matches($spot)) {
    # Send notification
  }

=head1 DESCRIPTION

Notify::Filter provides sophisticated filtering capabilities for
DXSpider spots. Filters can be based on band, mode, DXCC entity,
callsign patterns, spotter patterns, and more.

=head1 FILTER TYPES

=head2 Simple Filters

  { bands: ['20m', '40m'] }
  { modes: ['CW', 'FT8'] }
  { dxcc: [291, 'K'] }  # US stations (DXCC 291)
  { callsign: 'VK*' }   # Australian calls
  { spotter: '9M2*' }   # Spotters from Malaysia

=head2 Compound Filters

AND - All criteria must match:
  {
    and: [
      { bands: ['20m'] },
      { modes: ['CW'] }
    ]
  }

OR - Any criterion must match:
  {
    or: [
      { bands: ['20m'] },
      { bands: ['40m'] }
    ]
  }

=head2 Advanced Filters

Frequency range:
  { freq_min: 14000, freq_max: 14100 }

Comment contains:
  { comment_contains: 'IOTA' }

Multiple criteria (implicit AND):
  {
    bands: ['20m'],
    modes: ['CW'],
    dxcc: [291]
  }

=head1 METHODS

=head2 new(\@filters)

Create a new filter engine with an array of filter definitions.

=head2 matches($spot)

Check if a spot matches any of the configured filters.
Returns 1 if match, 0 otherwise.

=head2 apply_filter($spot, $filter)

Apply a single filter to a spot.

=head1 SPOT STRUCTURE

Spots should be hash references with:
  - freq: frequency in kHz
  - call: spotted callsign
  - time: unix timestamp
  - comment: spot comment
  - spotter: spotter callsign
  - band: band name (160m, 80m, etc.)
  - mode: mode (CW, SSB, FT8, etc.)

=head1 AUTHOR

9M2PJU-DXSpider-Docker Project

=cut
