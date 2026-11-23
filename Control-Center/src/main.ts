import { App } from './app/App'
import './styles/global.scss'

const host = document.querySelector<HTMLElement>('#app')
if (!host) throw new Error('Control Center mount point is missing')
App(host)
