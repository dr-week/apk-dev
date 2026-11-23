import { html, render, repeat } from '@zuari/dom'
import { effect } from '@zuari/signals'
import { GridGlyph, LayersGlyph, SearchGlyph, SparkleGlyph, TunerGlyph, UserGlyph } from '@zuari/glyphs'
import type { PageKey } from './pageTypes'

const links: Array<{ label: PageKey; glyph: typeof GridGlyph }> = [
  { label: 'Overview', glyph: GridGlyph }, { label: 'Apps', glyph: LayersGlyph },
  { label: 'Connections', glyph: SearchGlyph }, { label: 'Releases', glyph: LayersGlyph },
  { label: 'Activity', glyph: SearchGlyph }, { label: 'Settings', glyph: TunerGlyph },
]

export function Sidebar(page: { value: PageKey }, navigate: (key: PageKey) => void) {
  const view = html`<div class="shell"><aside class="sidebar"><div class="brand"><span class="brand-glyph"></span><div><strong>apk.dev</strong><small>CONTROL CENTER</small></div></div>
    <p class="nav-label">WORKSPACE</p><nav aria-label="Main navigation">${repeat(links, item => item.label, link => html`<button class="nav-item" data-page=${link.label} @click=${() => navigate(link.label)}><span data-glyph=${link.label}></span><span>${link.label}</span></button>`)}</nav>
    <div class="sidebar-bottom"><div class="health-card"><i class="health-dot"></i><div><strong>Factory health</strong><small>Toolchain available</small></div></div><div class="user-row"><span class="avatar">D</span><div><strong>Developer</strong><small>Local workspace</small></div><span class="user-glyph"></span></div></div></aside>
    <main class="workspace"><div class="topbar-slot"></div><div class="page-slot"></div></main></div>`
  const mounted = render(view)
  mounted.fragment.querySelector('.brand-glyph')?.replaceChildren(SparkleGlyph({ size: 19 }))
  mounted.fragment.querySelector('.user-glyph')?.replaceChildren(UserGlyph({ size: 16 }))
  links.forEach(({ label, glyph }) => mounted.fragment.querySelector(`[data-glyph="${label}"]`)?.replaceChildren(glyph({ size: 17 })))
  const buttons = Array.from(mounted.fragment.querySelectorAll<HTMLButtonElement>('.nav-item'))
  effect(() => buttons.forEach(button => button.classList.toggle('selected', page.value === button.dataset.page)))
  return mounted
}
