import { html } from '@zuari/dom'
import type { AppRecord } from '../../shared/contracts/app'

export function AppCard(app: AppRecord) {
  const ready = app.status === 'Ready for release'
  return html`<article class="app-card"><div class="app-card-top"><div class="app-icon ${app.tint}">${app.initials}</div><button class="card-more" aria-label="More actions">···</button></div>
    <div class="app-name-row"><div><h3>${app.name}</h3><span class="app-category">${app.category}<i></i> Android</span></div><span class="state-pill ${ready ? 'is-ready' : ''}"><i></i>${app.status}</span></div>
    <div class="package-line"><span>${app.packageId}</span><button aria-label="Open app details">↗</button></div>
    <div class="app-card-bottom"><div><small>CURRENT VERSION</small><strong>v${app.version}</strong></div><div><small>LAST UPDATED</small><strong>Nov 10, 2026</strong></div><span class="platform-tag">ANDROID</span></div></article>`
}
