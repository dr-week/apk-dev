import { html, render } from '@zuari/dom'
import type { PageKey } from '../../app/pageTypes'

export function renderPlaceholder(page: PageKey) {
  return render(html`<section class="page placeholder-page"><div class="eyebrow">WORKSPACE</div><h1>${page}</h1><p>This workspace is planned in the Control Center architecture.</p><div class="placeholder-card"><strong>Next phase</strong><span>Build and release history, provider integrations, and audit-ready workflows will connect here.</span></div></section>`)
}
