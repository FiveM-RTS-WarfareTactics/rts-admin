const Admin = {
    target: null,
    permission: null,
    data: null,

    async send(event, data) {
        return (await fetch('https://' + GetParentResourceName() + '/' + event, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        })).json();
    },

    init() {
        document.querySelectorAll('.tab').forEach(function(btn) {
            btn.onclick = function() {
                document.querySelectorAll('.tab, .tab-content, section').forEach(function(el) {
                    el.classList.remove('active');
                });
                btn.classList.add('active');
                document.getElementById('tab-' + btn.dataset.tab).classList.add('active');
            };
        });

        document.getElementById('btnRefresh').onclick = function() { Admin.send('refresh'); };
        document.getElementById('btnClose').onclick = function() { Admin.send('closePanel'); };
        document.getElementById('btnAdmin').onclick = function() { Admin.send('toggleAdminMode'); };

        document.getElementById('mkConfirm').onclick = function() {
            Admin.send('kick', { id: Admin.target, reason: document.getElementById('mkReason').value });
            closeModal('modalKick');
        };

        document.getElementById('mbConfirm').onclick = function() {
            let duration = parseInt(document.getElementById('mbDuration').value);
            if (duration === -1) {
                const dt = new Date(document.getElementById('mbCustomDate').value);
                duration = Math.max(0, Math.floor((dt.getTime() - Date.now()) / 1000));
            }
            Admin.send('ban', {
                id: Admin.target,
                dur: duration,
                reason: document.getElementById('mbReason').value
            });
            closeModal('modalBan');
        };

        document.getElementById('mmConfirm').onclick = function() {
            Admin.send('mute', {
                id: Admin.target,
                dur: parseInt(document.getElementById('mmDuration').value),
                reason: document.getElementById('mmReason').value
            });
            closeModal('modalMute');
        };

        document.getElementById('qaCleanMatches').onclick = function() {
                        Admin.confirmAction('End All Matches', 'This will terminate every active match.', function() { Admin.send('terminateMatch', { id: 'all' }); });
        };
        document.getElementById('qaClearMutes').onclick = function() {
            Admin.confirmAction('Clear All Mutes', 'Remove all active mutes?', function() { Admin.send('clearMutes'); });
        };
        document.getElementById('qaAnnounce').onclick = function() {
            document.getElementById('modalAnnounce').classList.remove('hidden');
        };
        document.getElementById('maConfirm').onclick = function() {
            Admin.send('announce', { message: document.getElementById('maMessage').value });
            closeModal('modalAnnounce');
            document.getElementById('maMessage').value = '';
        };
        document.getElementById('qaShutdown').onclick = function() {
                        Admin.confirmAction('Kick All Players', 'Kick every player except yourself?', function() { Admin.send('kick', { id: 'all' }); });
        };

        document.getElementById('qbArchitect').onclick = function() { Admin.send('enterArchitect'); };
        document.getElementById('qbLoadMap').onclick = function() {
            const sel = document.getElementById('bldExisting');
            if (sel && sel.value) {
                Admin.send('loadMap', { name: sel.value });
            }
        };
    },

    update(info) {
        Admin.data = info;
        Admin.permission = info.permission;
        setText('hsOnline', info.online || 0);
        setText('hsMatches', info.matchCount || 0);
        setText('hsRole', (info.permission || '--').toUpperCase());
        Admin.renderPlayers(info.players || []);
        Admin.renderMatches(info.matches || []);

        if (info.maps) {
            const sel = document.getElementById('bldExisting');
            sel.innerHTML = '';
            info.maps.forEach(function(name) {
                const opt = document.createElement('option');
                opt.value = name;
                opt.textContent = name;
                sel.appendChild(opt);
            });
        }

        document.getElementById('btnAdmin').style.display =
            (Admin.permission === 'admin' || Admin.permission === 'mod') ? '' : 'none';
    },

    renderPlayers(players) {
        const tbody = document.getElementById('playerRows');
        if (!players.length) {
            tbody.innerHTML = '<tr><td colspan="6" class="empty">No players</td></tr>';
            return;
        }
        tbody.innerHTML = players.map(function(p) {
            let row = '<tr>';
            row += '<td style="font-family:var(--mono);color:var(--muted)">' + p.id + '</td>';
            row += '<td><b>' + escapeHtml(p.name) + '</b>';
            if (p.isMuted) row += ' <span class="badge badge-muted">MUTED</span>';
            row += '</td>';
            row += '<td style="font-family:var(--mono)">' + p.ping + 'ms</td>';
            row += '<td style="font-family:var(--mono);color:var(--accent)">#' + p.bucket + '</td>';
            row += '<td>' + Admin.permissionBadge(p.permission) + '</td>';
            row += '<td><div class="act-row">' + Admin.actionButtons(p) + '</div></td>';
            row += '</tr>';
            return row;
        }).join('');
    },

    renderMatches(matches) {
        const grid = document.getElementById('matchGrid');
        if (!matches.length) {
            grid.innerHTML = '<div class="empty">No matches</div>';
            return;
        }
        grid.innerHTML = matches.map(function(m) {
            let card = '<div class="mcard">';
            card += '<h4>' + (m.mapName || '?').toUpperCase() + '</h4>';
            card += '<div class="match-players">';
            (m.players || []).forEach(function(p) {
                card += '<div class="mplayer">';
                card += '<span style="color:' + (p.team === 1 ? 'var(--accent)' : 'var(--red)') + '">T' + p.team + '</span>';
                card += '<span>' + (p.name || '?') + '</span>';
                card += '<span style="color:var(--muted)">' + (p.spawnedUnits || 0) + 'u</span>';
                card += '</div>';
            });
            card += '</div>';
            card += '<div class="mactions">';
            card += '<button class="mbtn" onclick="Admin.send(\'spectate\',{bucket:' + m.bucketId + ',cx:' + (m.cx||0) + ',cy:' + (m.cy||0) + ',cz:' + (m.cz||0) + '})">Spectate</button>';
            if (Admin.permission === 'admin') {
                card += '<button class="mbtn del" onclick="Admin.send(\'terminateMatch\',{id:\'' + m.matchId + '\'})">End</button>';
            }
            card += '</div></div>';
            return card;
        }).join('');
    },

    actionButtons(player) {
        let html = '<button class="act kick" onclick="Admin.openKick(' + player.id + ',\'' + escapeHtml(player.name) + '\')">Kick</button>';
        if (Admin.permission === 'admin') {
            html += '<button class="act ban" onclick="Admin.openBan(' + player.id + ',\'' + escapeHtml(player.name) + '\')">Ban</button>';
        }
        if (player.isMuted) {
            html += '<button class="act mute" onclick="Admin.send(\'unmute\',{id:' + player.id + '})">Unmute</button>';
        } else {
            html += '<button class="act mute" onclick="Admin.openMute(' + player.id + ',\'' + escapeHtml(player.name) + '\')">Mute</button>';
        }
        return html;
    },

    permissionBadge(level) {
        const badges = {
            admin:   '<span class="badge badge-admin">ADMIN</span>',
            mod:     '<span class="badge badge-mod">MOD</span>',
            support: '<span class="badge badge-support">SUPPORT</span>'
        };
        return badges[level] || '<span class="badge badge-player">PLAYER</span>';
    },

    openKick(id, name)  { Admin.target = id; setText('mkName', name); document.getElementById('modalKick').classList.remove('hidden'); },
    openBan(id, name)   { Admin.target = id; setText('mbName', name); document.getElementById('modalBan').classList.remove('hidden'); },
    openMute(id, name)  { Admin.target = id; setText('mmName', name); document.getElementById('modalMute').classList.remove('hidden'); },
    confirmAction(title, text, callback) {
        setText('mcTitle', title);
        setText('mcText', text);
        document.getElementById('mcConfirm').onclick = function() { callback(); closeModal('modalConfirm'); };
        document.getElementById('modalConfirm').classList.remove('hidden');
    }
};

// Shared helpers
function closeModal(id) {
    document.getElementById(id).classList.add('hidden');
}

function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
}

function escapeHtml(str) {
    return String(str || '').replace(/'/g, "\\'");
}

function onBanDurationChange() {
    const customDate = document.getElementById('mbCustomDate');
    customDate.style.display = document.getElementById('mbDuration').value === '-1' ? '' : 'none';
}

// NUI message handler
window.addEventListener('message', function(e) {
    if (!e.data || !e.data.action) return;
    const action = e.data.action;

    if (action === 'open')    { document.getElementById('root').classList.remove('hidden'); Admin.send('refresh'); }
    if (action === 'close')    document.getElementById('root').classList.add('hidden');
    if (action === 'hideUI')   document.body.style.display = 'none';
    if (action === 'showUI')   document.body.style.display = '';
    if (action === 'resetUI') { document.body.style.display = ''; Admin.send('refresh'); }
    if (action === 'update')   Admin.update(e.data.data);
});

document.addEventListener('DOMContentLoaded', function() { Admin.init(); });
