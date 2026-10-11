/*
 * Copyright (C) 2026 Claudio Guareschi <cguareschimd@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Click diagnostics, only with ?clicklog=1 in the page address: for each press on the map, how
 * long it was held, how far the pointer moved, what was under it at press and at release, whether
 * deck.gl reported a click, and whether follow traffic was moving the map. It finds why a click on
 * an arch is sometimes missed; it changes nothing the map does.
 */

const ROWS = 10;
// deck.gl reports a click when the tap gesture ends; this is ample time for it to arrive
const SETTLE_MS = 400;

export function clickLogEnabled(search = globalThis.location?.search || '') {
  return /[?&]clicklog=1(&|$)/.test(search);
}

export function createClickLog(container, deck, {pickingRadius, follow}) {
  if (!clickLogEnabled()) {
    return null;
  }
  const panel = document.createElement('div');
  Object.assign(panel.style, {
    position: 'absolute', left: '8px', bottom: '8px', zIndex: 5, maxWidth: 'calc(100% - 16px)',
    padding: '6px 8px', borderRadius: '4px', font: '11px/1.4 ui-monospace, Menlo, monospace',
    background: 'var(--fwmap-panel, #fff)', color: 'var(--fwmap-text, #333)',
    border: '1px solid rgba(128, 128, 128, .4)', pointerEvents: 'none', whiteSpace: 'pre',
  });
  panel.textContent = 'click log: press on the map';
  container.appendChild(panel);
  const rows = [];
  let press = null;
  let pending = null;

  const point = (event) => {
    const rect = container.getBoundingClientRect();
    return {x: event.clientX - rect.left, y: event.clientY - rect.top};
  };
  const under = (x, y) => {
    try {
      const info = deck.pickObject({x, y, radius: pickingRadius});
      return info?.object ? info.layer.id.replace('firewall-map-', '') : '-';
    } catch (error) {
      return 'error';
    }
  };
  const render = () => {
    panel.textContent = ['held  moved  under at press > release  deck click  follow  verdict',
      ...rows.map((row) => [
        `${String(row.ms).padStart(4)}ms`, `${String(row.px).padStart(3)}px`,
        `${row.down} > ${row.up}`.padEnd(24), String(row.clicked || 'none').padEnd(10),
        row.follow ? (row.flying ? 'flying' : 'on    ') : 'off   ', row.verdict,
      ].join('  '))].join('\n');
  };

  container.addEventListener('pointerdown', (event) => {
    const at = point(event);
    press = {start: performance.now(), ...at, down: under(at.x, at.y), follow: follow.follow, flying: follow.flying};
  }, true);
  container.addEventListener('pointerup', (event) => {
    if (!press) {
      return;
    }
    const at = point(event);
    const entry = {...press, ms: Math.round(performance.now() - press.start),
      px: Math.round(Math.hypot(at.x - press.x, at.y - press.y)), up: under(at.x, at.y), clicked: null};
    press = null;
    pending = entry;
    setTimeout(() => {
      if (pending === entry) {
        pending = null;
      }
      const aimed = entry.down !== '-' || entry.up !== '-';
      entry.verdict = entry.clicked ? 'selected' : !aimed ? 'nothing there'
        : entry.ms >= 250 ? 'MISSED: held too long' : entry.px >= 9 ? 'MISSED: moved' : 'MISSED';
      rows.unshift(entry);
      rows.length = Math.min(rows.length, ROWS);
      render();
      console.info('[firewall-map click]', JSON.stringify(entry));
    }, SETTLE_MS);
  }, true);

  return {
    /** deck.gl's onClick: what it picked, for the press being settled. */
    clicked(info) {
      if (pending) {
        pending.clicked = info?.object ? info.layer.id.replace('firewall-map-', '') : 'empty';
      }
    },
  };
}
