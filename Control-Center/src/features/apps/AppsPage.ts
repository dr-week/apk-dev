import { computed, signal, type Signal } from '@zuari/signals'
import { html, render, repeat } from '@zuari/dom'
import type { AppRecord } from '../../shared/contracts/app'
import { PlusGlyph, GridGlyph, LayersGlyph, TunerGlyph } from '@zuari/glyphs'
import { registeredApps } from '../../shared/data/apps'
import { AppCard } from './AppCard'

export function renderApps(query: Signal<string>, _onRegister: () => void) {
  const filter = signal('All apps')
  const sort = signal('Recently updated')
  const layout = signal<'grid' | 'list'>('grid')
  const visible = computed(() => registeredApps.filter(app => `${app.name} ${app.packageId} ${app.path}`.toLowerCase().includes(query.value.toLowerCase()) && (filter.value === 'All apps' || filter.value === app.status)).sort((a, b) => {
    if (sort.value === 'Name A–Z') return a.name.localeCompare(b.name)
    if (sort.value === 'Version') return b.version.localeCompare(a.version, undefined, { numeric: true })
    if (sort.value === 'Status') return a.status.localeCompare(b.status)
    return b.updated.localeCompare(a.updated)
  }))
  const view = html`<section class="page apps-page"><div class="page-heading"><div><div class="eyebrow">YOUR PORTFOLIO</div><h1>App library</h1><p>Every project, gathered in one place.</p></div><button class="button button-primary register" disabled title="Registration workflow is planned for the next phase"><span class="plus-glyph"></span> Register app</button></div>
    <div class="library-summary"><strong>03 <small>projects registered</small></strong><span><i></i> Apps registry <b>·</b> build data synced in a later phase</span></div>
    <div class="filter-toolbar"><div class="filter-tabs">${repeat(['All apps', 'In development', 'Ready for release'], label => label, label => html`<button data-filter=${label} @click=${() => filter.value = label}>${label}</button>`)}</div>
      <div class="toolbar-controls"><label class="sort-control"><span class="sort-glyph"></span><select><option>Recently updated</option><option>Recently built</option><option>Last published</option><option>Name A–Z</option><option>Version</option><option>Status</option></select></label><button class="icon-button subtle" aria-label="Filters"><span class="filter-glyph"></span></button><button class="icon-button subtle layout-btn" aria-label="Switch view"><span class="layout-glyph"></span></button></div></div>
    <div class="app-grid" data-layout=${layout.value}>${repeat<AppRecord>(() => visible.value, app => app.id, app => AppCard(app))}</div></section>`
  const mounted = render(view)
  mounted.fragment.querySelector('.plus-glyph')?.replaceChildren(PlusGlyph({ size: 16 }))
  mounted.fragment.querySelector('.sort-glyph')?.replaceChildren(LayersGlyph({ size: 15 }))
  mounted.fragment.querySelector('.filter-glyph')?.replaceChildren(TunerGlyph({ size: 16 }))
  mounted.fragment.querySelector('.layout-glyph')?.replaceChildren(GridGlyph({ size: 16 }))
  const filterButtons = Array.from(mounted.fragment.querySelectorAll<HTMLButtonElement>('[data-filter]'))
  const grid = mounted.fragment.querySelector('.app-grid')
  filterButtons.forEach(button => button.addEventListener('click', () => { filter.value = button.dataset.filter ?? 'All apps'; filterButtons.forEach(tab => tab.setAttribute('data-active', String(tab === button))) }))
  mounted.fragment.querySelector<HTMLSelectElement>('select')?.addEventListener('change', event => { sort.value = (event.target as HTMLSelectElement).value })
  mounted.fragment.querySelector<HTMLButtonElement>('.layout-btn')?.addEventListener('click', () => { layout.value = layout.value === 'grid' ? 'list' : 'grid'; grid?.setAttribute('data-layout', layout.value) })
  return mounted
}
