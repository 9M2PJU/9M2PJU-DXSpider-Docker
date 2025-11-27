#!/usr/bin/env perl
#
# DXSpider Prometheus Metrics Exporter
#
# A Mojolicious::Lite HTTP server that exposes DXSpider metrics
# in Prometheus text format on port 9100 (configurable).
#
# Usage: perl metrics_server.pl daemon -l http://*:9100
#
# Copyright (c) 2025 9M2PJU
#

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../perl";
use lib "$FindBin::Bin/../../local";

# DXSpider modules
use DXVars;
use DXUtil;
use DXDebug;
use Route;
use Route::Node;
use Route::User;
use Spot;
use DXUser;
use DXChannel;
use DXProt;
use Time::HiRes qw(time);

# Mojolicious
use Mojolicious::Lite -signatures;

# Configuration
my $METRICS_PORT = $ENV{CLUSTER_METRICS_PORT} || 9100;
my $start_time = time();
my %metrics_cache;
my $cache_ttl = $ENV{METRICS_CACHE_TTL} || 30; # Cache metrics for 30 seconds (configurable)

# =============================================================================
# Helper Functions
# =============================================================================

# Get DXSpider version from DXVars
sub get_dxspider_version {
    return $main::version || $DXProt::myprot_version || "unknown";
}

# Get callsign from DXVars
sub get_callsign {
    return $main::mycall || $DXVars::mycall || "UNKNOWN";
}

# Calculate uptime in seconds
sub get_uptime_seconds {
    my $uptime = 0;
    if (defined $main::starttime) {
        $uptime = time() - $main::starttime;
    } else {
        # Fallback: use metrics server start time
        $uptime = time() - $start_time;
    }
    return int($uptime);
}

# Get cluster statistics
sub get_cluster_stats {
    my %stats = (
        nodes => 0,
        total_nodes => 0,
        users => 0,
        local_users => 0,
        max_users => 0,
        max_local_users => 0,
    );

    eval {
        if ($main::routeroot) {
            # Get local connected users
            $stats{local_users} = scalar $main::routeroot->users;

            # Get local connected nodes
            $stats{nodes} = scalar $main::routeroot->nodes;

            # Get total users and nodes in cluster
            my ($nodes, $tot, $users, $maxlocalusers, $maxusers, $uptime, $localnodes) = Route::cluster();
            $stats{total_nodes} = $tot || 0;
            $stats{users} = $users || 0;
            $stats{max_local_users} = $maxlocalusers || 0;
            $stats{max_users} = $maxusers || 0;
        }
    };

    return \%stats;
}

# Get connected nodes by type
sub get_nodes_by_type {
    my %node_types = (
        spider => 0,
        clx => 0,
        dxnet => 0,
        ar_cluster => 0,
        cc_cluster => 0,
        other => 0,
    );

    eval {
        if ($main::routeroot) {
            my @nodes = $main::routeroot->nodes;
            foreach my $call (@nodes) {
                my $node = Route::Node::get($call);
                if ($node) {
                    my $ver = $node->version || '';
                    if ($ver =~ /spider/i) {
                        $node_types{spider}++;
                    } elsif ($ver =~ /clx/i) {
                        $node_types{clx}++;
                    } elsif ($ver =~ /dxnet/i) {
                        $node_types{dxnet}++;
                    } elsif ($ver =~ /ar-cluster/i) {
                        $node_types{ar_cluster}++;
                    } elsif ($ver =~ /cc cluster/i) {
                        $node_types{cc_cluster}++;
                    } else {
                        $node_types{other}++;
                    }
                }
            }
        }
    };

    return \%node_types;
}

# Get spot statistics
sub get_spot_stats {
    my %stats = (
        total => 0,
        by_band => {},
        last_minute => 0,
    );

    eval {
        # Count spots in dupefile (recent spots cache)
        my $dupefile = "$main::data/dupefile";
        if (-f $dupefile && open(my $fh, '<', $dupefile)) {
            my $now = time();
            my $one_min_ago = $now - 60;
            my %band_count;

            while (my $line = <$fh>) {
                chomp $line;
                my ($freq, $call, $time, $text) = split /\^/, $line;
                next unless defined $time;

                $stats{total}++;

                # Count spots in last minute
                if ($time >= $one_min_ago) {
                    $stats{last_minute}++;
                }

                # Categorize by band
                if (defined $freq) {
                    my $band = freq_to_band($freq);
                    $band_count{$band}++ if $band;
                }
            }
            close $fh;

            $stats{by_band} = \%band_count;
        }
    };

    return \%stats;
}

# Convert frequency to band
sub freq_to_band {
    my $freq = shift;
    return undef unless defined $freq;

    # Convert to kHz if needed
    $freq = $freq / 1000 if $freq > 30000;

    # Amateur radio bands
    return '160m' if $freq >= 1800 && $freq <= 2000;
    return '80m'  if $freq >= 3500 && $freq <= 4000;
    return '60m'  if $freq >= 5250 && $freq <= 5450;
    return '40m'  if $freq >= 7000 && $freq <= 7300;
    return '30m'  if $freq >= 10100 && $freq <= 10150;
    return '20m'  if $freq >= 14000 && $freq <= 14350;
    return '17m'  if $freq >= 18068 && $freq <= 18168;
    return '15m'  if $freq >= 21000 && $freq <= 21450;
    return '12m'  if $freq >= 24890 && $freq <= 24990;
    return '10m'  if $freq >= 28000 && $freq <= 29700;
    return '6m'   if $freq >= 50000 && $freq <= 54000;
    return '2m'   if $freq >= 144000 && $freq <= 148000;
    return '70cm' if $freq >= 420000 && $freq <= 450000;

    return 'other';
}

# Get traffic statistics
sub get_traffic_stats {
    my %stats = (
        bytes_in => 0,
        bytes_out => 0,
        msgs_in => 0,
        msgs_out => 0,
    );

    eval {
        # Aggregate from all DXChannel connections
        my @channels = DXChannel::get_all();
        foreach my $chan (@channels) {
            if ($chan && $chan->can('conn')) {
                my $conn = $chan->conn;
                if ($conn) {
                    $stats{bytes_in} += $conn->{rbytes} || 0;
                    $stats{bytes_out} += $conn->{wbytes} || 0;
                }
            }
        }
    };

    return \%stats;
}

# Get all metrics (with caching)
sub get_all_metrics {
    my $now = time();

    # Return cached metrics if still fresh
    if ($metrics_cache{timestamp} &&
        ($now - $metrics_cache{timestamp}) < $cache_ttl) {
        return $metrics_cache{data};
    }

    # Collect fresh metrics
    my $version = get_dxspider_version();
    my $callsign = get_callsign();
    my $uptime = get_uptime_seconds();
    my $cluster = get_cluster_stats();
    my $nodes_by_type = get_nodes_by_type();
    my $spots = get_spot_stats();
    my $traffic = get_traffic_stats();

    # Build metrics
    my @metrics;

    # Info metric (gauge with labels)
    push @metrics, sprintf(
        '# HELP dxspider_info DXSpider node information',
        '# TYPE dxspider_info gauge',
        'dxspider_info{version="%s",callsign="%s"} 1',
        $version, $callsign
    );

    # Uptime
    push @metrics, sprintf(
        '# HELP dxspider_uptime_seconds DXSpider uptime in seconds',
        '# TYPE dxspider_uptime_seconds gauge',
        'dxspider_uptime_seconds %d',
        $uptime
    );

    # Connected users
    push @metrics, sprintf(
        '# HELP dxspider_users_connected Number of connected users',
        '# TYPE dxspider_users_connected gauge',
        'dxspider_users_connected %d',
        $cluster->{local_users}
    );

    # Total users in cluster
    push @metrics, sprintf(
        '# HELP dxspider_cluster_users_total Total users in cluster network',
        '# TYPE dxspider_cluster_users_total gauge',
        'dxspider_cluster_users_total %d',
        $cluster->{users}
    );

    # Connected nodes by type
    push @metrics, '# HELP dxspider_nodes_connected Number of connected nodes by type';
    push @metrics, '# TYPE dxspider_nodes_connected gauge';
    foreach my $type (sort keys %$nodes_by_type) {
        push @metrics, sprintf(
            'dxspider_nodes_connected{type="%s"} %d',
            $type, $nodes_by_type->{$type}
        );
    }

    # Total nodes in cluster
    push @metrics, sprintf(
        '# HELP dxspider_cluster_nodes_total Total nodes in cluster network',
        '# TYPE dxspider_cluster_nodes_total gauge',
        'dxspider_cluster_nodes_total %d',
        $cluster->{total_nodes}
    );

    # Spots total by band
    push @metrics, '# HELP dxspider_spots_total Total DX spots by band';
    push @metrics, '# TYPE dxspider_spots_total counter';
    foreach my $band (sort keys %{$spots->{by_band}}) {
        push @metrics, sprintf(
            'dxspider_spots_total{band="%s"} %d',
            $band, $spots->{by_band}{$band}
        );
    }

    # Spots per minute
    push @metrics, sprintf(
        '# HELP dxspider_spots_per_minute DX spots in the last minute',
        '# TYPE dxspider_spots_per_minute gauge',
        'dxspider_spots_per_minute %d',
        $spots->{last_minute}
    );

    # Traffic statistics
    push @metrics, sprintf(
        '# HELP dxspider_bytes_in_total Total bytes received',
        '# TYPE dxspider_bytes_in_total counter',
        'dxspider_bytes_in_total %d',
        $traffic->{bytes_in}
    );

    push @metrics, sprintf(
        '# HELP dxspider_bytes_out_total Total bytes transmitted',
        '# TYPE dxspider_bytes_out_total counter',
        'dxspider_bytes_out_total %d',
        $traffic->{bytes_out}
    );

    # Process metrics
    push @metrics, sprintf(
        '# HELP dxspider_process_start_time_seconds Unix timestamp when process started',
        '# TYPE dxspider_process_start_time_seconds gauge',
        'dxspider_process_start_time_seconds %d',
        $main::starttime || $start_time
    );

    my $metrics_text = join("\n", @metrics) . "\n";

    # Cache the results
    $metrics_cache{timestamp} = $now;
    $metrics_cache{data} = $metrics_text;

    return $metrics_text;
}

# =============================================================================
# Mojolicious Routes
# =============================================================================

# Health check endpoint
get '/' => sub ($c) {
    $c->render(text => "DXSpider Prometheus Metrics Exporter\n" .
                      "Metrics available at /metrics\n");
};

# Prometheus metrics endpoint
get '/metrics' => sub ($c) {
    eval {
        my $metrics = get_all_metrics();
        $c->render(text => $metrics, format => 'txt');
    };

    if ($@) {
        app->log->error("Error generating metrics: $@");
        $c->render(
            text => "# Error generating metrics: $@\n",
            status => 500,
            format => 'txt'
        );
    }
};

# Health check endpoint for monitoring
get '/health' => sub ($c) {
    my $healthy = 1;
    my $status = "ok";

    eval {
        # Check if we can access DXSpider internals
        my $callsign = get_callsign();
        $healthy = 0 if $callsign eq "UNKNOWN";
    };

    if ($@) {
        $healthy = 0;
        $status = "error: $@";
    }

    $c->render(
        json => {
            status => $healthy ? 'healthy' : 'unhealthy',
            message => $status,
            uptime => get_uptime_seconds(),
        },
        status => $healthy ? 200 : 503
    );
};

# =============================================================================
# Application Startup
# =============================================================================

# Configure hypnotoad (production server)
app->config(
    hypnotoad => {
        listen => ["http://*:$METRICS_PORT"],
        workers => 2,
        clients => 100,
        accepts => 100,
        graceful_timeout => 10,
        heartbeat_timeout => 30,
        inactivity_timeout => 60,
    }
);

# Logging
app->log->level('info');
app->log->info("DXSpider Prometheus Metrics Exporter starting on port $METRICS_PORT");

# Start the application
app->start;
