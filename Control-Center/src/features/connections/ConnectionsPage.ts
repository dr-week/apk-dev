import { html, render, repeat } from '@zuari/dom'
import { ExternalLinkGlyph, PlusGlyph } from '@zuari/glyphs'

const stores = [
  { id: 'play', name: 'Google Play', logo: 'G', tone: 'google', info: 'Publish Android apps to Google Play Console.', method: 'OAuth · Developer API', action: 'Connect account' },
  { id: 'amazon', name: 'Amazon Appstore', logo: 'a', tone: 'amazon', info: 'Manage supported app updates and release status.', method: 'Login with Amazon · API', action: 'Connect account' },
  { id: 'fdroid', name: 'F-Droid', logo: 'F', tone: 'fdroid', info: 'Prepare source metadata for repository review.', method: 'Source submission', action: 'View workflow' },
  { id: 'apkpure', name: 'APKPure', logo: 'A', tone: 'apkpure', info: 'Organize your APKPure listing and releases.', method: 'Portal handoff', action: 'View workflow' },
  { id: 'indus', name: 'Indus Appstore', logo: 'I', tone: 'indus', info: 'Prepare releases for the Indus Appstore portal.', method: 'Portal handoff', action: 'View workflow' },
]

export function renderConnections() {
  const mounted = render(html`<section class="page connections-page"><div class="page-heading"><div><div class="eyebrow">STORE ACCESS</div><h1>Connections</h1><p>Manage publisher access and store destinations.</p></div><button class="button button-primary" disabled title="Secure OAuth callback setup is required"><span class="plus-glyph"></span> Add connection</button></div>
    <div class="identity-panel"><div class="identity-symbol">G</div><div class="identity-copy"><span class="identity-label">CONTROL CENTER IDENTITY</span><strong>Dashboard sign-in</strong><p>Google login for this workspace stays separate from publishing access.</p></div><span class="identity-state"><i></i> Not connected</span><button class="identity-connect" disabled>Connect Google account</button></div>
    <div class="security-note"><span class="lock-mark">⌑</span><div><strong>Publishing permissions stay explicit.</strong><p>Google Play publishing needs its own Developer API authorization and selected account.</p></div><span class="secure-mark">SECURE BY DESIGN</span></div>
    <div class="section-heading"><div><h2>Available stores</h2><p>Connect a store or follow its manual release route.</p></div><span class="connection-count"><i></i> 0 connected</span></div>
    <div class="provider-grid">${repeat(stores, store => store.id, store => html`<article class="provider-card"><div class="provider-top"><div class="provider-logo ${store.tone}">${store.logo}</div><span class="not-connected"><i></i> Not connected</span></div><h3>${store.name}</h3><p>${store.info}</p><div class="provider-method">${store.method}</div><button class="connect-button" disabled>${store.action}</button></article>`)}</div>
    <p class="provider-footnote">Connections are disabled in this preview until secure credential storage and provider authorization are configured.</p></section>`)
  mounted.fragment.querySelector('.plus-glyph')?.replaceChildren(PlusGlyph({ size: 16 }))
  mounted.fragment.querySelectorAll('.provider-card').forEach(card => card.querySelector('.provider-method')?.append(ExternalLinkGlyph({ size: 14 })))
  return mounted
}
