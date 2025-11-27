/**
 * DXSpider Dashboard - Additional JavaScript
 *
 * Main application logic is in index.html.ep using Alpine.js.
 * This file is for future extensions and utilities.
 */

/**
 * Audio notification for new spots (optional enhancement)
 */
class SpotNotifier {
    constructor() {
        this.enabled = false;
        this.audioContext = null;
    }

    enable() {
        this.enabled = true;
        if (!this.audioContext) {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
        }
    }

    disable() {
        this.enabled = false;
    }

    playBeep(frequency = 800, duration = 100) {
        if (!this.enabled || !this.audioContext) return;

        const oscillator = this.audioContext.createOscillator();
        const gainNode = this.audioContext.createGain();

        oscillator.connect(gainNode);
        gainNode.connect(this.audioContext.destination);

        oscillator.frequency.value = frequency;
        oscillator.type = 'sine';

        gainNode.gain.setValueAtTime(0.3, this.audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, this.audioContext.currentTime + duration / 1000);

        oscillator.start(this.audioContext.currentTime);
        oscillator.stop(this.audioContext.currentTime + duration / 1000);
    }

    notifyNewSpot() {
        this.playBeep(880, 80);
    }
}

/**
 * Local storage manager for dashboard preferences
 */
class DashboardPreferences {
    constructor() {
        this.storageKey = 'dxspider_dashboard_prefs';
    }

    save(key, value) {
        try {
            const prefs = this.load();
            prefs[key] = value;
            localStorage.setItem(this.storageKey, JSON.stringify(prefs));
        } catch (e) {
            console.warn('Failed to save preferences:', e);
        }
    }

    load() {
        try {
            const data = localStorage.getItem(this.storageKey);
            return data ? JSON.parse(data) : {};
        } catch (e) {
            console.warn('Failed to load preferences:', e);
            return {};
        }
    }

    get(key, defaultValue = null) {
        const prefs = this.load();
        return prefs[key] !== undefined ? prefs[key] : defaultValue;
    }
}

/**
 * Callsign lookup utility
 */
class CallsignLookup {
    static isValidCallsign(callsign) {
        // Basic amateur radio callsign validation
        const pattern = /^[A-Z0-9]{1,3}[0-9][A-Z0-9]{0,3}[A-Z]$/;
        return pattern.test(callsign);
    }

    static extractPrefix(callsign) {
        // Extract country prefix from callsign
        const match = callsign.match(/^([A-Z0-9]{1,3}[0-9])/);
        return match ? match[1] : '';
    }

    static stripSSID(callsign) {
        // Remove SSID (-10, /P, etc.) from callsign
        return callsign.split(/[-\/]/)[0];
    }
}

/**
 * Frequency/Band utilities
 */
class FrequencyUtils {
    static getBandFromFrequency(freqKhz) {
        const bands = {
            '160m': [1800, 2000],
            '80m':  [3500, 4000],
            '60m':  [5250, 5450],
            '40m':  [7000, 7300],
            '30m':  [10100, 10150],
            '20m':  [14000, 14350],
            '17m':  [18068, 18168],
            '15m':  [21000, 21450],
            '12m':  [24890, 24990],
            '10m':  [28000, 29700],
            '6m':   [50000, 54000],
            '2m':   [144000, 148000],
            '70cm': [420000, 450000],
        };

        for (const [band, [low, high]] of Object.entries(bands)) {
            if (freqKhz >= low && freqKhz <= high) {
                return band;
            }
        }

        return 'other';
    }

    static formatFrequency(freqKhz) {
        if (freqKhz >= 1000) {
            return `${(freqKhz / 1000).toFixed(1)} MHz`;
        }
        return `${freqKhz.toFixed(1)} kHz`;
    }
}

/**
 * Export utilities for spot data
 */
class SpotExporter {
    static exportToCSV(spots) {
        const headers = ['Time', 'Frequency', 'Callsign', 'Spotter', 'Comment', 'Band'];
        const rows = spots.map(spot => [
            spot.formatted_time,
            spot.formatted_freq,
            spot.callsign,
            spot.spotter,
            spot.comment,
            spot.band
        ]);

        const csvContent = [
            headers.join(','),
            ...rows.map(row => row.map(cell => `"${cell}"`).join(','))
        ].join('\n');

        return csvContent;
    }

    static downloadCSV(spots, filename = 'dxspider_spots.csv') {
        const csv = this.exportToCSV(spots);
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    }
}

// Make utilities available globally
window.SpotNotifier = SpotNotifier;
window.DashboardPreferences = DashboardPreferences;
window.CallsignLookup = CallsignLookup;
window.FrequencyUtils = FrequencyUtils;
window.SpotExporter = SpotExporter;

console.log('DXSpider Dashboard utilities loaded');
