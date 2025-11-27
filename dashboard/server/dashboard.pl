#!/usr/bin/env perl

#
# DXSpider Web Dashboard
# Mojolicious::Lite server providing web interface and API endpoints
#
# Copyright (c) 2025 9M2PJU
# Licensed under the same terms as DXSpider
#

use strict;
use warnings;
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(encode_json decode_json);
use FindBin;
use lib "$FindBin::Bin/../../perl";
use DXUtil;
use Spot;
use DXChannel;
use Route::Node;
use Route::User;
use DXUser;
use DXVars;
use Prefix;
use Bands;
use Time::HiRes qw(time);

# Configuration
my $SPIDER_DIR = $ENV{SPIDER_INSTALL_DIR} || '/spider';
my $DASHBOARD_PORT = $ENV{DASHBOARD_PORT} || 8080;
my $MAX_SPOTS = $ENV{DASHBOARD_MAX_SPOTS} || 100;
my $CACHE_TTL = 5; # seconds

# Cache for reducing DXSpider file access
my %cache = (
    spots => { data => [], timestamp => 0 },
    nodes => { data => [], timestamp => 0 },
    users => { data => [], timestamp => 0 },
    stats => { data => {}, timestamp => 0 },
);

# Static file serving
app->static->paths->[0] = app->home->rel_file('public');

# Template path
push @{app->renderer->paths}, app->home->rel_file('templates');

# Security headers
app->hook(after_dispatch => sub ($c) {
    $c->res->headers->header('X-Frame-Options' => 'DENY');
    $c->res->headers->header('X-Content-Type-Options' => 'nosniff');
    $c->res->headers->header('X-XSS-Protection' => '1; mode=block');
    $c->res->headers->header('Referrer-Policy' => 'no-referrer');
});

# CORS for development/reverse proxy (disabled by default for security)
my $cors_origin = $ENV{DASHBOARD_CORS_ORIGIN} || '';
if ($cors_origin) {
    app->hook(before_dispatch => sub ($c) {
        $c->res->headers->header('Access-Control-Allow-Origin' => $cors_origin);
        $c->res->headers->header('Access-Control-Allow-Methods' => 'GET, OPTIONS');
        $c->res->headers->header('Access-Control-Allow-Headers' => 'Content-Type');
    });
}

#
# Helper Functions
#

# Parse spot array into structured hash
sub parse_spot {
    my @spot_array = @_;

    # Spot format: [freq, call, time, comment, spotter, origin, dxcc_spotter,
    #               origin_node, itu, zone, itu_spotter, zone_spotter, state, state_spotter, ip]
    return {
        frequency => $spot_array[0] || 0,
        callsign => $spot_array[1] || 'UNKNOWN',
        time => $spot_array[2] || time(),
        comment => $spot_array[3] || '',
        spotter => $spot_array[4] || 'UNKNOWN',
        origin => $spot_array[6] || '',
        timestamp => $spot_array[2] || time(),
        band => Bands::get_band($spot_array[0] || 0),
        formatted_time => _format_time($spot_array[2] || time()),
        formatted_freq => sprintf("%.1f", $spot_array[0] || 0),
    };
}

# Format timestamp
sub _format_time {
    my $timestamp = shift;
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($timestamp);
    return sprintf("%02d:%02d", $hour, $min);
}

# Get band name from frequency
sub get_band_name {
    my $freq = shift;
    return '' unless $freq;

    # Amateur radio band mapping (in kHz)
    my %bands = (
        '160m' => [1800, 2000],
        '80m'  => [3500, 4000],
        '60m'  => [5250, 5450],
        '40m'  => [7000, 7300],
        '30m'  => [10100, 10150],
        '20m'  => [14000, 14350],
        '17m'  => [18068, 18168],
        '15m'  => [21000, 21450],
        '12m'  => [24890, 24990],
        '10m'  => [28000, 29700],
        '6m'   => [50000, 54000],
        '2m'   => [144000, 148000],
        '70cm' => [420000, 450000],
    );

    foreach my $band (keys %bands) {
        my ($low, $high) = @{$bands{$band}};
        return $band if $freq >= $low && $freq <= $high;
    }

    return 'other';
}

#
# Routes
#

# Main dashboard page
get '/' => sub ($c) {
    $c->render(
        template => 'index',
        cluster_callsign => $main::mycall || $ENV{CLUSTER_CALLSIGN} || 'UNKNOWN',
        cluster_qth => $main::myqth || $ENV{CLUSTER_QTH} || 'Unknown Location',
        cluster_locator => $main::mylocator || $ENV{CLUSTER_LOCATOR} || '',
    );
};

# API: Get recent spots
get '/api/spots' => sub ($c) {
    my $limit = $c->param('limit') || 50;
    my $band = $c->param('band') || '';
    my $search = uc($c->param('search') || '');

    $limit = $MAX_SPOTS if $limit > $MAX_SPOTS;

    # Check cache
    my $now = time();
    my $spots;

    if ($now - $cache{spots}{timestamp} < $CACHE_TTL) {
        $spots = $cache{spots}{data};
    } else {
        # Fetch from DXSpider
        my @raw_spots = Spot::search('', '', '', 0, $limit);
        $spots = [map { parse_spot(@$_) } @raw_spots];

        # Update cache
        $cache{spots} = { data => $spots, timestamp => $now };
    }

    # Filter by band if specified
    if ($band) {
        $spots = [grep { $_->{band} eq $band } @$spots];
    }

    # Filter by search term if specified
    if ($search) {
        $spots = [grep {
            index($_->{callsign}, $search) >= 0 ||
            index($_->{spotter}, $search) >= 0 ||
            index(uc($_->{comment}), $search) >= 0
        } @$spots];
    }

    $c->render(json => {
        success => 1,
        count => scalar(@$spots),
        spots => $spots,
    });
};

# API: Server-Sent Events for live spot updates
get '/api/spots/stream' => sub ($c) {
    $c->res->headers->content_type('text/event-stream');
    $c->res->headers->cache_control('no-cache');

    # Keep connection alive
    my $id = Mojo::IOLoop->recurring(5 => sub {
        my @recent_spots = Spot::search('', '', '', 0, 10);
        my $spots = [map { parse_spot(@$_) } @recent_spots];

        $c->write("event: spots\n");
        $c->write("data: " . encode_json({spots => $spots}) . "\n\n");
    });

    # Clean up on disconnect
    $c->on(finish => sub {
        Mojo::IOLoop->remove($id);
    });
};

# API: Get connected nodes
get '/api/nodes' => sub ($c) {
    my $now = time();
    my $nodes;

    if ($now - $cache{nodes}{timestamp} < $CACHE_TTL) {
        $nodes = $cache{nodes}{data};
    } else {
        my @node_calls = map { $_->call } DXChannel::get_all_nodes();
        $nodes = [];

        foreach my $call (@node_calls) {
            my $clref = Route::Node::get($call);
            my $uref = DXUser::get_current($call);

            next unless $clref || $uref;

            my $node_info = {
                callsign => $call,
                connected => $clref ? 1 : 0,
                type => 'node',
            };

            if ($uref) {
                $node_info->{sort} = $uref->is_spider ? 'Spider' :
                                    $uref->is_clx ? 'CLX' :
                                    $uref->is_ak1a ? 'AK1A' : 'Unknown';
                $node_info->{version} = $uref->version || '';
            }

            push @$nodes, $node_info;
        }

        $cache{nodes} = { data => $nodes, timestamp => $now };
    }

    $c->render(json => {
        success => 1,
        count => scalar(@$nodes),
        nodes => $nodes,
    });
};

# API: Get connected users
get '/api/users' => sub ($c) {
    my $now = time();
    my $users;

    if ($now - $cache{users}{timestamp} < $CACHE_TTL) {
        $users = $cache{users}{data};
    } else {
        my $node = $main::routeroot;
        my @user_calls = $node ? $node->users : ();

        $users = [];
        foreach my $call (@user_calls) {
            my $uref = Route::User::get($call);
            push @$users, {
                callsign => $call,
                here => $uref ? $uref->here : 0,
            };
        }

        $cache{users} = { data => $users, timestamp => $now };
    }

    $c->render(json => {
        success => 1,
        count => scalar(@$users),
        users => $users,
    });
};

# API: Get statistics
get '/api/stats' => sub ($c) {
    my $now = time();
    my $stats;

    if ($now - $cache{stats}{timestamp} < $CACHE_TTL) {
        $stats = $cache{stats}{data};
    } else {
        # Count spots in last hour
        my @hour_spots = Spot::search('', '', '', 0, 1000);
        my $hour_ago = time() - 3600;
        my $spots_last_hour = grep { $_->[2] >= $hour_ago } @hour_spots;

        # Get user count
        my $node = $main::routeroot;
        my @users = $node ? $node->users : ();

        # Get node count
        my @nodes = DXChannel::get_all_nodes();

        # Calculate band distribution
        my %band_counts;
        foreach my $spot (@hour_spots[0..49]) {
            my $band = get_band_name($spot->[0]);
            $band_counts{$band}++;
        }

        $stats = {
            spots_last_hour => $spots_last_hour,
            connected_users => scalar(@users),
            connected_nodes => scalar(@nodes),
            band_distribution => \%band_counts,
            uptime_seconds => time() - $^T,
            cluster_callsign => $main::mycall || 'UNKNOWN',
        };

        $cache{stats} = { data => $stats, timestamp => $now };
    }

    $c->render(json => {
        success => 1,
        stats => $stats,
    });
};

# API: Health check
get '/api/health' => sub ($c) {
    $c->render(json => {
        status => 'ok',
        timestamp => time(),
        cluster => $main::mycall || 'UNKNOWN',
    });
};

# Start the application
app->start('daemon', '-l', "http://*:$DASHBOARD_PORT");

__END__

=head1 NAME

dashboard.pl - DXSpider Web Dashboard Server

=head1 SYNOPSIS

  perl dashboard.pl

=head1 DESCRIPTION

Mojolicious::Lite web server providing a modern web dashboard for DXSpider.
Provides real-time DX spot viewing, node/user monitoring, and statistics.

=head1 ENVIRONMENT VARIABLES

=over 4

=item SPIDER_INSTALL_DIR

Path to DXSpider installation (default: /spider)

=item DASHBOARD_PORT

Port for dashboard web server (default: 8080)

=item DASHBOARD_MAX_SPOTS

Maximum number of spots to return (default: 100)

=back

=head1 API ENDPOINTS

=over 4

=item GET /

Main dashboard HTML page

=item GET /api/spots

Get recent DX spots (JSON)

Parameters: limit, band, search

=item GET /api/spots/stream

Server-Sent Events stream for live spot updates

=item GET /api/nodes

Get connected nodes (JSON)

=item GET /api/users

Get connected users (JSON)

=item GET /api/stats

Get cluster statistics (JSON)

=item GET /api/health

Health check endpoint (JSON)

=back

=head1 AUTHOR

9M2PJU

=cut
