import { signal } from '@zuari/signals'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'
import { showPage } from './showPage'
import type { PageKey } from './pageTypes'

export function App(host: HTMLElement) {
  const page = signal<PageKey>('Overview')
  const query = signal('')
  const rendered = Sidebar(page, next => { page.value = next })
  host.append(rendered.fragment)
  const topbar = Topbar(page, query)
  host.querySelector('.topbar-slot')?.replaceWith(topbar.fragment)
  const content = host.querySelector<HTMLElement>('.page-slot')
  if (content) showPage(content, page, query)
}
