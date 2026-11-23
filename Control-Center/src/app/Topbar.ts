import { html, render } from '@zuari/dom'
import { BellGlyph, SearchGlyph, UserGlyph } from '@zuari/glyphs'
import type { PageKey } from './pageTypes'

export function Topbar(page: { value: PageKey }, query: { value: string }) {
  const mounted = render(html`<header class="topbar"><div class="breadcrumbs"><span>Workspace</span><b>/</b><strong>${() => page.value}</strong></div>
    <div class="top-actions"><label class="search-box"><span class="search-glyph"></span><input aria-label="Search registered apps" placeholder="Search apps, releases…" /><kbd>⌘ K</kbd></label>
      <button class="icon-button" aria-label="Notifications"><span class="bell-glyph"></span><i></i></button><button class="profile-switch"><span class="avatar small">D</span><span class="user-glyph"></span></button></div></header>`)
  mounted.fragment.querySelector('.search-glyph')?.replaceChildren(SearchGlyph({ size: 16 }))
  mounted.fragment.querySelector('.bell-glyph')?.replaceChildren(BellGlyph({ size: 17 }))
  mounted.fragment.querySelector('.user-glyph')?.replaceChildren(UserGlyph({ size: 14 }))
  mounted.fragment.querySelector<HTMLInputElement>('input')?.addEventListener('input', event => { query.value = (event.target as HTMLInputElement).value })
  return mounted
}
