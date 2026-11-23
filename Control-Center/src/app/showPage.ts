import { effect, type Signal } from '@zuari/signals'
import type { PageKey } from './pageTypes'
import { renderOverview } from '../features/overview/OverviewPage'
import { renderApps } from '../features/apps/AppsPage'
import { renderConnections } from '../features/connections/ConnectionsPage'
import { renderPlaceholder } from '../shared/ui/Placeholder'

export function showPage(host: HTMLElement, page: Signal<PageKey>, query: Signal<string>) {
  let cleanup: () => void = () => {}
  effect(() => {
    const current = page.value
    query.value
    cleanup()
    const view = current === 'Overview' ? renderOverview(() => page.value = 'Apps')
      : current === 'Apps' ? renderApps(query, () => {})
      : current === 'Connections' ? renderConnections()
      : renderPlaceholder(current)
    host.replaceChildren(view.fragment)
    cleanup = view.destroy
  })
}
