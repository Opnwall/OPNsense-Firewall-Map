{#
 # Copyright (C) 2026 Claudio Guareschi <cguareschimd@gmail.com>
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 #
 # 1. Redistributions of source code must retain the above copyright notice,
 #    this list of conditions and the following disclaimer.
 #
 # 2. Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 #
 # THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 # INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 # AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 # AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 # OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 # SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 # INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 # CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 # ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 # POSSIBILITY OF SUCH DAMAGE.
 #}

<link rel="stylesheet" href="/ui/css/firewall-map.css?v={{ styleVersion }}">
<link rel="stylesheet" href="/ui/css/flags/flag-icon.css">
<script>
    // The strings the page shares with the dashboard widget (and the renderer) come from the widget's
    // translations (sharedText, see IndexController, already plain text); the ones below are the
    // page's own, and win where both exist. fwlang._() returns HTML-escaped text and the page escapes
    // again where it builds HTML, so they are decoded once here; json_encode makes each a valid
    // JavaScript string.
    function firewallMapPlain(strings) {
        const box = document.createElement('textarea');
        Object.keys(strings).forEach(function (key) {
            box.innerHTML = strings[key];
            strings[key] = box.value;
        });
        return strings;
    }
    // what this user may do (see IndexController::permissions()): only flags, true or false
    window.FirewallMapPermissions = {{ permissions }};
    window.FirewallMapPageText = Object.assign({{ sharedText }}, firewallMapPlain({
        firewall_map: {{ fwlang._('Firewall Map')|json_encode }},
        starting: {{ fwlang._('Warming up…')|json_encode }},
        reading: {{ fwlang._('Reading data…')|json_encode }},
        unavailable: {{ fwlang._('Live flow data is unavailable')|json_encode }},
        webgl: {{ fwlang._('WebGL is required for Firewall Map+')|json_encode }},
        downloading: {{ fwlang._('Downloading the geolocation database…')|json_encode }},
        all_services: {{ fwlang._('All services')|json_encode }},
        all_interfaces: {{ fwlang._('All interfaces')|json_encode }},
        all_hosts: {{ fwlang._('All inside hosts')|json_encode }},
        all_countries: {{ fwlang._('All countries')|json_encode }},
        no_talkers: {{ fwlang._('No traffic yet')|json_encode }},
        filter_hint: {{ fwlang._('Show only this on the map')|json_encode }},
        click_hint: {{ fwlang._('Click an endpoint or arc on the map for details and actions.')|json_encode }},
        ids_flow: {{ fwlang._('IDS flow')|json_encode }},
        ids_flows: {{ fwlang._('IDS flows')|json_encode }},
        ids_address: {{ fwlang._('IDS address')|json_encode }},
        ids_addresses: {{ fwlang._('IDS addresses')|json_encode }},
        sec_connection: {{ fwlang._('Connection')|json_encode }},
        sec_firewall: {{ fwlang._('Firewall')|json_encode }},
        sec_reputation: {{ fwlang._('Reputation')|json_encode }},
        via: {{ fwlang._('Public side')|json_encode }},
        closed: {{ fwlang._('closed')|json_encode }},
        transferred: {{ fwlang._('Transferred')|json_encode }},
        decision: {{ fwlang._('Decision')|json_encode }},
        allowed: {{ fwlang._('Allowed')|json_encode }},
        rule: {{ fwlang._('Rule')|json_encode }},
        severity: {{ fwlang._('Severity')|json_encode }},
        ips_dropped: {{ fwlang._('dropped by IPS')|json_encode }},
        copy: {{ fwlang._('Copy')|json_encode }},
        whois: {{ fwlang._('Whois')|json_encode }},
        show_states: {{ fwlang._('States')|json_encode }},
        kill_states: {{ fwlang._('Kill states')|json_encode }},
        add_to_alias: {{ fwlang._('Add to alias')|json_encode }},
        add_country: {{ fwlang._('Add country to GeoIP alias')|json_encode }},
        close: {{ fwlang._('Close')|json_encode }},
        confirm: {{ fwlang._('Confirm')|json_encode }},
        cancel: {{ fwlang._('Cancel')|json_encode }},
        kill_confirm: {{ fwlang._('Kill all firewall states involving')|json_encode }},
        kill_scope: {{ fwlang._('This ends the connections of every inside host to this address, and any traffic routed through it.')|json_encode }},
        killed: {{ fwlang._('States killed:')|json_encode }},
        add_confirm: {{ fwlang._('Add')|json_encode }},
        no_aliases: {{ fwlang._('No suitable alias exists yet. Create one under Firewall ▸ Aliases first.')|json_encode }},
        action_failed: {{ fwlang._('The action failed')|json_encode }},
        states_for: {{ fwlang._('States for')|json_encode }},
        no_states: {{ fwlang._('No states found.')|json_encode }},
        more_states: {{ fwlang._('Only the first 100 states are shown.')|json_encode }},
        interface: {{ fwlang._('Interface')|json_encode }},
        protocol: {{ fwlang._('Protocol')|json_encode }},
        source: {{ fwlang._('Source')|json_encode }},
        destination: {{ fwlang._('Destination')|json_encode }},
        state: {{ fwlang._('State')|json_encode }},
        bytes: {{ fwlang._('Bytes')|json_encode }},
        investigate: {{ fwlang._('Investigate')|json_encode }},
        looking_up: {{ fwlang._('Looking up registry, routing and reputation…')|json_encode }},
        lookup_failed: {{ fwlang._('Lookup failed')|json_encode }},
        retry: {{ fwlang._('Retry')|json_encode }},
        registry: {{ fwlang._('Registry (RDAP)')|json_encode }},
        routing: {{ fwlang._('Routing (RIPEstat)')|json_encode }},
        owner: {{ fwlang._('Owner')|json_encode }},
        network: {{ fwlang._('Network')|json_encode }},
        range: {{ fwlang._('Range')|json_encode }},
        country: {{ fwlang._('Country')|json_encode }},
        abuse_contact: {{ fwlang._('Abuse contact')|json_encode }},
        registered: {{ fwlang._('Registered')|json_encode }},
        updated: {{ fwlang._('updated')|json_encode }},
        prefix: {{ fwlang._('Prefix')|json_encode }},
        origin_as: {{ fwlang._('Origin AS')|json_encode }},
        announced: {{ fwlang._('Announced')|json_encode }},
        yes: {{ fwlang._('yes')|json_encode }},
        no: {{ fwlang._('no')|json_encode }},
        confidence: {{ fwlang._('Abuse confidence')|json_encode }},
        reports: {{ fwlang._('Reports (90 days)')|json_encode }},
        reporters: {{ fwlang._('reporters')|json_encode }},
        last_reported: {{ fwlang._('Last reported')|json_encode }},
        usage: {{ fwlang._('Usage')|json_encode }},
        abuseipdb_hint: {{ fwlang._('Add an AbuseIPDB API key in the Firewall Map settings to see abuse reports here.')|json_encode }},
        mark_threat: {{ fwlang._('Mark as threat')|json_encode }},
        mark_confirm: {{ fwlang._('Add')|json_encode }},
        mark_scope: {{ fwlang._('to the FWMAP_Watchlist alias? The map will flag its traffic as a threat. No firewall rule is added.')|json_encode }},
        marked: {{ fwlang._('Its traffic is flagged on the map within five minutes.')|json_encode }},
        inbound: {{ fwlang._('Inbound')|json_encode }},
        outbound: {{ fwlang._('Outbound')|json_encode }},
        this_firewall: {{ fwlang._('this firewall')|json_encode }},
        blacklist: {{ fwlang._('AbuseIPDB blacklist (downloaded daily)')|json_encode }},
        blacklist_addresses: {{ fwlang._('addresses')|json_encode }},
        blacklist_pending: {{ fwlang._('Not downloaded yet')|json_encode }},
        blacklist_error: {{ fwlang._('last attempt failed')|json_encode }},
        blacklist_no_key: {{ fwlang._('Add an AbuseIPDB API key in the Firewall Map settings to download it.')|json_encode }},
        active: {{ fwlang._('Active')|json_encode }},
        allowed_flagged: {{ fwlang._('Allowed · flagged')|json_encode }},
        block_attempts: {{ fwlang._('Attempts')|json_encode }},
        blocked: {{ fwlang._('Blocked')|json_encode }},
        blocked_attempts: {{ fwlang._('Blocked attempts')|json_encode }},
        blocked_flagged: {{ fwlang._('Blocked · flagged')|json_encode }},
        flagged: {{ fwlang._('flagged')|json_encode }},
        ips_dropped_flagged: {{ fwlang._('Dropped by IPS · flagged')|json_encode }},
        ips_dropped_title: {{ fwlang._('Dropped by IPS')|json_encode }},
        clean: {{ fwlang._('Clean')|json_encode }},
        connections: {{ fwlang._('Connections')|json_encode }},
        current_rate: {{ fwlang._('Current rate')|json_encode }},
        egress: {{ fwlang._('Egress')|json_encode }},
        idle: {{ fwlang._('Idle')|json_encode }},
        ids_on_address: {{ fwlang._('Alerts on this address in the last hour (not necessarily this traffic)')|json_encode }},
        ids_on_connection: {{ fwlang._('Alerts raised by this exact connection')|json_encode }},
        ids_only: {{ fwlang._('Seen by Suricata')|json_encode }},
        ids_only_sub: {{ fwlang._('No open connection')|json_encode }},
        in_minutes: {{ fwlang._('in {minutes} min')|json_encode }},
        inside_side: {{ fwlang._('Inside side')|json_encode }},
        listed: {{ fwlang._('Listed')|json_encode }},
        more: {{ fwlang._('More')|json_encode }},
        no_connection: {{ fwlang._('No connection is open right now.')|json_encode }},
        no_ids: {{ fwlang._('No IDS alerts for this address')|json_encode }},
        no_ids_sub: {{ fwlang._('Suricata has not alerted on this address in the last hour.')|json_encode }},
        no_ids_talkers: {{ fwlang._('No Suricata alerts in the last hour')|json_encode }},
        select_hint: {{ fwlang._('Show the details')|json_encode }},
        last_updated_ago: {{ fwlang._('Last updated {time} ago')|json_encode }},
        ids_alert: {{ fwlang._('IDS alert')|json_encode }},
        open_ids: {{ fwlang._('Open Suricata alerts')|json_encode }},
        open_log: {{ fwlang._('Open the firewall log')|json_encode }},
        port_word: {{ fwlang._('Port')|json_encode }},
        checking: {{ fwlang._('checking…')|json_encode }},
        check_now: {{ fwlang._('Check now')|json_encode }},
        no_key: {{ fwlang._('no API key')|json_encode }},
        not_listed_short: {{ fwlang._('Not listed')|json_encode }},
        fw_passed: {{ fwlang._('Passed')|json_encode }},
        fw_blocked: {{ fwlang._('Blocked')|json_encode }},
        fw_not_seen: {{ fwlang._('not seen by the firewall')|json_encode }},
        ips_dropped_short: {{ fwlang._('IPS drop')|json_encode }},
        query: {{ fwlang._('query')|json_encode }},
        more_connection: {{ fwlang._('more connection')|json_encode }},
        more_connections: {{ fwlang._('more connections')|json_encode }},
        connection_col: {{ fwlang._('Connection')|json_encode }},
        no_snapshot: {{ fwlang._('No connection snapshot yet: it is taken the next time this address has an open connection.')|json_encode }},
        show_more: {{ fwlang._('Show {count} more')|json_encode }},
        showing: {{ fwlang._('{shown} of {total} shown')|json_encode }},
        dismiss_all: {{ fwlang._('Dismiss all ({count})')|json_encode }},
        dismiss_all_confirm: {{ fwlang._('Dismiss all {count} new entries? You can reopen them from the Dismissed tab.')|json_encode }},
        delete_all: {{ fwlang._('Delete all ({count})')|json_encode }},
        delete_all_confirm: {{ fwlang._('Delete all {count} {status} entries for good? This cannot be undone. New traffic from these addresses would create new entries.')|json_encode }},
        sample: {{ fwlang._('sample')|json_encode }},
        other_target: {{ fwlang._('other target')|json_encode }},
        other_targets: {{ fwlang._('other targets')|json_encode }},
        targets_seen: {{ fwlang._('Targets')|json_encode }},
        other_hosts: {{ fwlang._('more inside')|json_encode }},
        more_details: {{ fwlang._('More details')|json_encode }},
        services_seen: {{ fwlang._('Services seen')|json_encode }},
        remote_port: {{ fwlang._('Remote port')|json_encode }},
        duration: {{ fwlang._('Duration')|json_encode }},
        alerts_short: {{ fwlang._('alerts')|json_encode }},
        flow_one: {{ fwlang._('flow')|json_encode }},
        flow_many: {{ fwlang._('flows')|json_encode }},
        organization: {{ fwlang._('Organization')|json_encode }},
        pf_sets: {{ fwlang._('PF sets')|json_encode }},
        set_country: {{ fwlang._('country blocklist: membership decided by the firewall, which may differ from the geolocation')|json_encode }},
        set_operational: {{ fwlang._('operational set')|json_encode }},
        other_ports: {{ fwlang._('Other ports')|json_encode }},
        other_services: {{ fwlang._('Other services')|json_encode }},
        port_forward: {{ fwlang._('Port forward')|json_encode }},
        remote_addresses_here: {{ fwlang._('addresses here:')|json_encode }},
        connections_here: {{ fwlang._('connections to this address:')|json_encode }},
        remote_side: {{ fwlang._('Remote side')|json_encode }},
        sec_ids_long: {{ fwlang._('IDS (Suricata)')|json_encode }},
        started: {{ fwlang._('Started')|json_encode }},
        started_inside_long: {{ fwlang._('Outbound · started inside')|json_encode }},
        started_outside_long: {{ fwlang._('Inbound · started outside')|json_encode }},
        target: {{ fwlang._('Target')|json_encode }},
        this_firewall_title: {{ fwlang._('This firewall')|json_encode }},
        tried: {{ fwlang._('Tried')|json_encode }},
        review_queue: {{ fwlang._('Threats')|json_encode }},
        review_intro: {{ fwlang._('Flagged traffic organized by observed firewall and IPS disposition')|json_encode }},
        record_threats: {{ fwlang._('Record in the background')|json_encode }},
        record_threats_hint: {{ fwlang._('Keep recording while the map is closed, as long as the widget is on a dashboard. Setting a status never changes firewall rules.')|json_encode }},
        queue_search: {{ fwlang._('Filter by address, network, list, host…')|json_encode }},
        time_ago: {{ fwlang._('{time} ago')|json_encode }},
        first_seen_ago: {{ fwlang._('First seen {time} ago')|json_encode }},
        blacklist_short: {{ fwlang._('AbuseIPDB blacklist')|json_encode }},
        status_new: {{ fwlang._('New')|json_encode }},
        status_reviewed: {{ fwlang._('Reviewed')|json_encode }},
        status_dismissed: {{ fwlang._('Dismissed')|json_encode }},
        status_blocked: {{ fwlang._('Blocked')|json_encode }},
        status_all: {{ fwlang._('All')|json_encode }},
        status_passed: {{ fwlang._('Passed / reached host')|json_encode }},
        status_firewall_blocked: {{ fwlang._('Blocked by firewall')|json_encode }},
        status_ips_dropped: {{ fwlang._('Dropped by IPS')|json_encode }},
        disposition_passed: {{ fwlang._('Passed · reached host')|json_encode }},
        disposition_firewall_blocked: {{ fwlang._('Blocked at firewall')|json_encode }},
        disposition_ips_dropped: {{ fwlang._('Dropped by IPS')|json_encode }},
        passed_attention: {{ fwlang._('need attention')|json_encode }},
        mark_reviewed: {{ fwlang._('Mark reviewed')|json_encode }},
        dismiss: {{ fwlang._('Dismiss')|json_encode }},
        reopen: {{ fwlang._('Reopen')|json_encode }},
        block: {{ fwlang._('Block…')|json_encode }},
        block_title: {{ fwlang._('Add to a blocking alias')|json_encode }},
        block_hint: {{ fwlang._('The address is added to the alias you choose. It is blocked only if a firewall rule uses that alias.')|json_encode }},
        edit_note: {{ fwlang._('Note')|json_encode }},
        note_title: {{ fwlang._('Note for')|json_encode }},
        save: {{ fwlang._('Save')|json_encode }},
        first_seen: {{ fwlang._('First seen')|json_encode }},
        samples: {{ fwlang._('samples')|json_encode }},
        peak: {{ fwlang._('peak')|json_encode }},
        seen_after_block: {{ fwlang._('Traffic was seen after it was marked blocked: check that a rule uses the alias.')|json_encode }},
        snapshot_population: {{ fwlang._('from {count} flows')|json_encode }},
        snapshot_ranking_bounded: {{ fwlang._('ranking was bounded')|json_encode }},
        map_profile: {{ fwlang._('{profile} ranking')|json_encode }},
        map_interval: {{ fwlang._('refreshed every {seconds} s')|json_encode }},
        map_carp_backup: {{ fwlang._('CARP backup: traffic is passing through the master')|json_encode }},
        map_carp_mirror: {{ fwlang._("CARP backup: mirroring the master's connections (no traffic data)")|json_encode }},
        map_waiting_restart: {{ fwlang._('The collector is restarting: the map resumes with its first ranked sample')|json_encode }},
        map_waiting_profile: {{ fwlang._('Applying the {profile} ranking profile: the map resumes with its first ranked sample')|json_encode }},
        mirror_sub: {{ fwlang._('Mirrored from the CARP master (no traffic data)')|json_encode }},
        probe_sub: {{ fwlang._('{count} connection attempts, no data')|json_encode }},
        snapshot_loading: {{ fwlang._('Loading the snapshot…')|json_encode }},
        snapshot_waiting: {{ fwlang._('The map is waiting for the collector: take the snapshot when it resumes')|json_encode }},
        map_ranking_bounded: {{ fwlang._('the top-ranked of {count} flows')|json_encode }},
        map_ranking_warming: {{ fwlang._('ranking settling after a busy period')|json_encode }},
        listed_flows_one: {{ fwlang._('{count} to a listed address')|json_encode }},
        listed_flows_many: {{ fwlang._('{count} to listed addresses')|json_encode }},
        dismiss_shown: {{ fwlang._('Dismiss {count} shown')|json_encode }},
        dismiss_shown_confirm: {{ fwlang._('Dismiss the {count} new entries this search shows? You can reopen them from the Dismissed tab.')|json_encode }},
        delete_shown: {{ fwlang._('Delete {count} shown')|json_encode }},
        queue_no_match: {{ fwlang._('No entries match this search.')|json_encode }},
        queue_empty: {{ fwlang._('Nothing here.')|json_encode }},
        queue_empty_passed: {{ fwlang._('No unreviewed flagged traffic reached a host.')|json_encode }},
        queue_empty_firewall_blocked: {{ fwlang._('No unreviewed flagged traffic was blocked by PF.')|json_encode }},
        queue_empty_ips_dropped: {{ fwlang._('No unreviewed flagged traffic was dropped by IPS.')|json_encode }},
        queue_empty_reviewed: {{ fwlang._('No entries marked reviewed yet.')|json_encode }},
        queue_empty_dismissed: {{ fwlang._('No dismissed entries.')|json_encode }},
        queue_empty_all: {{ fwlang._('Threat history is empty.')|json_encode }},
        resize_hint: {{ fwlang._('Drag or use the arrow keys to resize; double-click or Home to reset')|json_encode }},
        today: {{ fwlang._('Today')|json_encode }},
        snapshot: {{ fwlang._('Snapshot')|json_encode }},
        snapshots: {{ fwlang._('Snapshots')|json_encode }},
        snapshot_flows_one: {{ fwlang._('{count} flow')|json_encode }},
        snapshot_flows_many: {{ fwlang._('{count} flows')|json_encode }},
        snapshot_flagged_one: {{ fwlang._('{count} flagged')|json_encode }},
        snapshot_flagged_many: {{ fwlang._('{count} flagged')|json_encode }},
        snapshot_view: {{ fwlang._('Open')|json_encode }},
        snapshot_note: {{ fwlang._('Snapshot note')|json_encode }},
        snapshot_add_note: {{ fwlang._('Add a note')|json_encode }},
        snapshot_edit_note: {{ fwlang._('Edit note')|json_encode }},
        snapshot_download: {{ fwlang._('Download as JSON')|json_encode }},
        snapshot_delete: {{ fwlang._('Delete snapshot')|json_encode }},
        snapshot_delete_confirm: {{ fwlang._('Delete the snapshot taken')|json_encode }},
        snapshot_by: {{ fwlang._('by')|json_encode }},
        snapshot_partial: {{ fwlang._('summary only')|json_encode }},
        snapshot_unknown: {{ fwlang._('Detail completeness unknown')|json_encode }},
        snapshot_truncated: {{ fwlang._('Truncated detail')|json_encode }},
        snapshot_complete: {{ fwlang._('Complete detail within capture scope')|json_encode }},
        snapshot_captured_flows: {{ fwlang._('{captured} flows captured of {available} available')|json_encode }},
        snapshot_omitted_geo: {{ fwlang._('{count} additional flows without geographic data')|json_encode }},
        snapshot_captured_states: {{ fwlang._('{captured} of {available} matching PF rows saved across captured remotes')|json_encode }},
        snapshot_partial_hint: {{ fwlang._('The collector did not answer in time: the map as shown was saved, without the connection states.')|json_encode }},
        snapshot_no_states: {{ fwlang._('This snapshot was saved without connection states.')|json_encode }},
        snapshot_show: {{ fwlang._('Show this snapshot')|json_encode }},
        snapshot_older: {{ fwlang._('Older snapshot')|json_encode }},
        snapshot_newer: {{ fwlang._('Newer snapshot')|json_encode }},
        no_snapshots: {{ fwlang._('No snapshots yet: take one with the camera button on the map.')|json_encode }},
        snapshots_kept: {{ fwlang._('The newest {count} are kept, for up to {days} days.')|json_encode }},
        timeline: {{ fwlang._('Timeline')|json_encode }},
        timeline_expand: {{ fwlang._('Show the timeline')|json_encode }},
        timeline_collapse: {{ fwlang._('Collapse the timeline')|json_encode }},
        timeline_previous_day: {{ fwlang._('Previous day with snapshots')|json_encode }},
        timeline_next_day: {{ fwlang._('Next day with snapshots')|json_encode }},
        snapshots_here_one: {{ fwlang._('{count} snapshot')|json_encode }},
        snapshots_here_many: {{ fwlang._('{count} snapshots taken close together')|json_encode }},
        captured_at: {{ fwlang._('Captured {time}')|json_encode }},
        as_captured_at: {{ fwlang._('As captured at {time}')|json_encode }},
        may_have_closed: {{ fwlang._('this connection may have closed since')|json_encode }},
        states_at: {{ fwlang._('States at')|json_encode }},
        current_states: {{ fwlang._('Current states')|json_encode }},
    }));
</script>
<script src="/ui/js/firewall-map-renderer.js?v={{ rendererVersion }}"></script>
<script src="/ui/js/firewall-map-page.js?v={{ pageVersion }}"></script>
{% if diagnosticsVersion %}
<script src="/ui/js/firewall-map-diagnostics.js?v={{ diagnosticsVersion }}"></script>
{% endif %}

<div class="content-box" style="padding: 12px;">
    <div id="fwmap-layout">
        <div id="fwmap-main">
    <div id="fwmap-toolbar">
            <div id="fwmap-mode" class="btn-group btn-group-sm" role="group" aria-label="{{ fwlang._('Map mode') }}">
                <button type="button" id="fwmap-mode-live" class="btn btn-default active" data-mode="live" aria-pressed="true"><i class="fwmap-live"></i> {{ fwlang._('Live') }}</button>
                <button type="button" id="fwmap-mode-snapshots" class="btn btn-default" data-mode="snapshots" aria-pressed="false" disabled><i class="fa fa-fw fa-camera" aria-hidden="true"></i> {{ fwlang._('Snapshots') }} <span class="badge" id="fwmap-snapshot-count"></span></button>
            </div>
            <span class="fwmap-tool-sep" aria-hidden="true"></span>
            <div id="fwmap-chips" role="group" aria-label="{{ fwlang._('Filters') }}">
                <div class="btn-group btn-group-sm fwmap-filter" data-filter="traffic" data-icon="fa-fw fa-arrows-up-down">
                    <select id="fwmap-filter-traffic" class="selectpicker" data-width="fit" data-style="btn-default btn-sm" data-icon-base="fa" data-size="12" aria-label="{{ fwlang._('Traffic') }}">
                        <option value="all">{{ fwlang._('All traffic') }}</option>
                        <option value="permitted">{{ fwlang._('Allowed') }}</option>
                        <option value="blocked">{{ fwlang._('Blocked') }}</option>
                        <option value="threats">{{ fwlang._('Threats that got through') }}</option>
                        <option value="ids">{{ fwlang._('IDS alerts') }}</option>
                        <option value="ids_flows">{{ fwlang._('IDS flows') }}</option>
                        <option value="ids_addresses">{{ fwlang._('IDS addresses') }}</option>
                    </select>
                    <button type="button" class="btn btn-primary fwmap-filter-clear" title="{{ fwlang._('Show all') }}" aria-label="{{ fwlang._('Show all') }}"><i class="fa fa-xmark" aria-hidden="true"></i></button>
                </div>
                <div class="btn-group btn-group-sm fwmap-filter" data-filter="iface" data-icon="fa-fw fa-sitemap">
                    <select id="fwmap-filter-iface" class="selectpicker" data-width="fit" data-style="btn-default btn-sm" data-icon-base="fa" data-size="12" data-live-search="true" aria-label="{{ fwlang._('Interface') }}"><option value="">{{ fwlang._('All interfaces') }}</option></select>
                    <button type="button" class="btn btn-primary fwmap-filter-clear" title="{{ fwlang._('Show all') }}" aria-label="{{ fwlang._('Show all') }}"><i class="fa fa-xmark" aria-hidden="true"></i></button>
                </div>
                <div class="btn-group btn-group-sm fwmap-filter" data-filter="host" data-icon="fa-fw fa-desktop">
                    <select id="fwmap-filter-host" class="selectpicker" data-width="fit" data-style="btn-default btn-sm" data-icon-base="fa" data-size="12" data-live-search="true" aria-label="{{ fwlang._('Inside host') }}"><option value="">{{ fwlang._('All inside hosts') }}</option></select>
                    <button type="button" class="btn btn-primary fwmap-filter-clear" title="{{ fwlang._('Show all') }}" aria-label="{{ fwlang._('Show all') }}"><i class="fa fa-xmark" aria-hidden="true"></i></button>
                </div>
                <div class="btn-group btn-group-sm fwmap-filter" data-filter="service" data-icon="fa-fw fa-table-cells-large">
                    <select id="fwmap-filter-service" class="selectpicker" data-width="fit" data-style="btn-default btn-sm" data-icon-base="fa" data-size="12" data-live-search="true" aria-label="{{ fwlang._('Service') }}"><option value="">{{ fwlang._('All services') }}</option></select>
                    <button type="button" class="btn btn-primary fwmap-filter-clear" title="{{ fwlang._('Show all') }}" aria-label="{{ fwlang._('Show all') }}"><i class="fa fa-xmark" aria-hidden="true"></i></button>
                </div>
                <div class="btn-group btn-group-sm fwmap-filter" data-filter="country" data-icon="fa-fw fa-globe">
                    <select id="fwmap-filter-country" class="selectpicker" data-width="fit" data-style="btn-default btn-sm" data-icon-base="fa" data-size="12" data-live-search="true" aria-label="{{ fwlang._('Country') }}"><option value="">{{ fwlang._('All countries') }}</option></select>
                    <button type="button" class="btn btn-primary fwmap-filter-clear" title="{{ fwlang._('Show all') }}" aria-label="{{ fwlang._('Show all') }}"><i class="fa fa-xmark" aria-hidden="true"></i></button>
                </div>
                <div class="btn-group btn-group-sm" id="fwmap-filter-asn">
                    <span class="btn btn-primary fwmap-asn-label"><i class="fa fa-fw fa-building" aria-hidden="true"></i> <span></span></span>
                    <a href="#" role="button" class="btn btn-primary fwmap-filter-clear" title="{{ fwlang._('Remove') }}" aria-label="{{ fwlang._('Remove') }}"><i class="fa fa-xmark" aria-hidden="true"></i></a>
                </div>
                <div class="btn-group btn-group-sm" id="fwmap-more-wrap" style="display:none">
                    <button type="button" class="btn btn-default dropdown-toggle" id="fwmap-more" aria-haspopup="true" aria-expanded="false"><i class="fa fa-fw fa-filter" aria-hidden="true"></i> {{ fwlang._('Filters') }} <span class="badge" id="fwmap-more-count"></span> <span class="caret"></span></button>
                    <div class="dropdown-menu" id="fwmap-more-menu" role="group" aria-label="{{ fwlang._('More filters') }}"></div>
                </div>
                <button id="fwmap-reset" class="btn btn-default btn-sm" type="button" title="{{ fwlang._('Reset filters') }}" aria-label="{{ fwlang._('Reset filters') }}" style="display:none"><i class="fa fa-fw fa-rotate-left" aria-hidden="true"></i></button>
            </div>
            <button id="fwmap-review" class="btn btn-default btn-sm" type="button" style="display:none" title="{{ fwlang._('Threats') }}">
                <i class="fa fa-fw fa-list" aria-hidden="true"></i><span class="fwmap-tool-text">{{ fwlang._('Threats') }}</span> <span class="fwmap-pill fwmap-pill-danger" id="fwmap-review-count"></span>
            </button>
        </div>
        <div id="fwmap-map">
            <div id="fwmap-grid" aria-hidden="true"></div>
            <div id="fwmap-canvas"></div>
            <div id="fwmap-legend">
                <span class="fwmap-legend-mode"><span class="fwmap-legend-label">{{ fwlang._('Color') }}</span>
                    <select id="fwmap-color" class="selectpicker" data-width="fit" data-style="btn-default btn-xs" aria-label="{{ fwlang._('Color') }}">
                        <option value="initiator">{{ fwlang._('Inbound / outbound') }}</option>
                        <option value="direction">{{ fwlang._('Download / upload') }}</option>
                        <option value="egress">{{ fwlang._('By egress') }}</option>
                        <option value="service">{{ fwlang._('By service') }}</option>
                    </select></span>
                <span id="fwmap-legend-items"></span>
            </div>
            <div id="fwmap-controls">
                <div id="fwmap-zoom" class="btn-group-vertical btn-group-sm" role="group" aria-label="{{ fwlang._('Zoom') }}">
                    <button type="button" class="btn btn-default" data-zoom="1" title="{{ fwlang._('Zoom in') }}" aria-label="{{ fwlang._('Zoom in') }}"><i class="fa fa-fw fa-plus" aria-hidden="true"></i></button>
                    <button type="button" class="btn btn-default" data-zoom="-1" title="{{ fwlang._('Zoom out') }}" aria-label="{{ fwlang._('Zoom out') }}"><i class="fa fa-fw fa-minus" aria-hidden="true"></i></button>
                    <button type="button" class="btn btn-default" data-zoom="fit" title="{{ fwlang._('Whole world') }}" aria-label="{{ fwlang._('Whole world') }}"><i class="fa fa-fw fa-expand" aria-hidden="true"></i></button>
                    <button type="button" class="btn btn-default" id="fwmap-follow" data-zoom="follow" aria-pressed="false" title="{{ fwlang._('Follow traffic: keep the map zoomed to the current arcs') }}" aria-label="{{ fwlang._('Follow traffic') }}"><i class="fa fa-fw fa-crosshairs" aria-hidden="true"></i></button>
                </div>
                <button type="button" class="btn btn-default btn-sm" id="fwmap-camera" title="{{ fwlang._('Take a snapshot: save the map as it is now, to review later') }}" aria-label="{{ fwlang._('Take a snapshot') }}"><i class="fa fa-fw fa-camera" aria-hidden="true"></i></button>
            </div>
            <div id="fwmap-banner" style="display:none" aria-live="polite"></div>
            <div id="fwmap-geo"></div>
            <div id="fwmap-timeline" style="display:none"></div>
            <div id="fwmap-credit"></div>
        </div>
        <div id="fwmap-statusbar"><div id="fwmap-status" aria-live="polite"></div><div id="fwmap-updated"></div></div>
        </div>
        <div class="fwmap-splitter fwmap-splitter-v" id="fwmap-split-side" title="{{ fwlang._('Drag or use the arrow keys to resize; double-click or Home to reset') }}"></div>
        <div id="fwmap-side">
            <div id="fwmap-talkers">
                <!-- each tab shows its icon; only the open one also shows its name (the others on hover) -->
                <ul class="nav nav-tabs" role="tablist" aria-label="{{ fwlang._('Top talkers') }}">
                    <li class="active" role="presentation"><a href="#" role="tab" aria-selected="true" data-tab="hosts" title="{{ fwlang._('Hosts') }}"><i class="fa fa-fw fa-desktop" aria-hidden="true"></i><span class="fwmap-tab-text">{{ fwlang._('Hosts') }}</span></a></li>
                    <li role="presentation"><a href="#" role="tab" aria-selected="false" data-tab="countries" title="{{ fwlang._('Countries') }}"><i class="fa fa-fw fa-globe" aria-hidden="true"></i><span class="fwmap-tab-text">{{ fwlang._('Countries') }}</span></a></li>
                    <li role="presentation"><a href="#" role="tab" aria-selected="false" data-tab="networks" title="{{ fwlang._('Networks') }}"><i class="fa fa-fw fa-sitemap" aria-hidden="true"></i><span class="fwmap-tab-text">{{ fwlang._('Networks') }}</span></a></li>
                    <li role="presentation"><a href="#" role="tab" aria-selected="false" data-tab="ids" title="{{ fwlang._('IDS') }}"><i class="fa fa-fw fa-shield-halved" aria-hidden="true"></i><span class="fwmap-tab-text">{{ fwlang._('IDS') }}</span></a></li>
                    <li role="presentation"><a href="#" role="tab" aria-selected="false" data-tab="snapshots" title="{{ fwlang._('Snapshots') }}"><i class="fa fa-fw fa-camera" aria-hidden="true"></i><span class="fwmap-tab-text">{{ fwlang._('Snapshots') }}</span></a></li>
                </ul>
                <div class="fwmap-talker-tools">
                    <div class="input-group input-group-sm">
                        <span class="input-group-addon"><i class="fa fa-fw fa-magnifying-glass" aria-hidden="true"></i></span>
                        <input type="search" class="form-control" id="fwmap-talker-search" placeholder="{{ fwlang._('Search…') }}" aria-label="{{ fwlang._('Search…') }}">
                    </div>
                    <select class="selectpicker" id="fwmap-talker-sort" data-width="fit" data-style="btn-default btn-sm" aria-label="{{ fwlang._('Sort') }}">
                        <option value="rate">{{ fwlang._('Top talkers') }}</option>
                        <option value="flows">{{ fwlang._('Most flows') }}</option>
                        <option value="name">{{ fwlang._('Name') }}</option>
                    </select>
                </div>
                <div id="fwmap-talkers-list"></div>
            </div>
            <div class="fwmap-splitter fwmap-splitter-h" id="fwmap-split-details" title="{{ fwlang._('Drag or use the arrow keys to resize; double-click or Home to reset') }}"></div>
            <div id="fwmap-details-box">
                <div id="fwmap-details"></div>
            </div>
        </div>
    </div>
</div>

<script>
$(function () {
    const label = {{ fwlang._('Map')|json_encode }};
    document.querySelectorAll('a[href="/ui/firewallmap"]').forEach(function (link) {
        const walker = document.createTreeWalker(link, NodeFilter.SHOW_TEXT);
        let node;
        while ((node = walker.nextNode())) {
            if (node.textContent.trim() === 'Map') node.textContent = node.textContent.replace('Map', label);
        }
    });
});
</script>
