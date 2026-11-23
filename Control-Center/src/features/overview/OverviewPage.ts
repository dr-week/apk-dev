import { html, render, repeat } from '@zuari/dom'
import { SparkleGlyph } from '@zuari/glyphs'
import { ArrowRightGlyph, BoxGlyph, CloudGlyph, WarningGlyph } from '../../shared/ui/glyphs'
import { registeredApps } from '../../shared/data/apps'
import { AppCard } from '../apps/AppCard'

export function renderOverview(openApps: () => void) {
  const view = html`<section class="page overview-page"><div class="page-heading"><div><div class="eyebrow"><i class="live-dot"></i> RELEASE WORKSPACE</div><h1>Your apps, <em>in orbit.</em></h1><p>One calm place to prepare, package, and ship every idea.</p></div><button class="button button-quiet"><span class="avatar tiny">D</span> My workspace</button></div>
    <section class="hero-card"><div class="hero-glow"></div><div class="hero-copy"><div class="hero-label"><span class="hero-spark"></span> YOUR RELEASE DESK</div><h2>Good morning, Dishant.</h2><p>One app is ready for its next chapter.<br/>Your release flow is looking clear.</p><button class="button button-primary" @click=${openApps}>Open release desk <span class="arrow-glyph"></span></button></div>
      <div class="orbit-art"><div class="orbit orbit-one"></div><div class="orbit orbit-two"></div><div class="planet"><span class="box-glyph"></span></div><span class="orbit-star star-a">✦</span><span class="orbit-star star-b">✧</span></div>
      <div class="hero-foot"><span><i class="status-dot ready"></i> BUILD FACTORY ONLINE</span><span>Local workspace <b>·</b> just now</span></div></section>
    <div class="metrics"><article class="metric-card"><span class="metric-icon violet"><span class="apps-glyph"></span></span><small>Registered apps</small><strong>03</strong><span class="metric-change">All projects</span></article>
      <article class="metric-card"><span class="metric-icon amber"><span class="cloud-glyph"></span></span><small>Connected stores</small><strong>00</strong><span class="metric-change">Setup needed</span></article>
      <article class="metric-card"><span class="metric-icon mint"><span class="build-glyph"></span></span><small>Build artifacts</small><strong>06</strong><span class="metric-change">In release ledger</span></article>
      <article class="metric-card"><span class="metric-icon rose"><span class="warning-glyph"></span></span><small>Needs attention</small><strong>01</strong><span class="metric-change">Release ready</span></article></div>
    <div class="section-heading"><div><h2>App library</h2><p>Your registered projects, ready when you are.</p></div><button class="text-button" @click=${openApps}>View all apps <span class="arrow-glyph"></span></button></div>
    <div class="app-grid">${repeat(registeredApps, app => app.id, app => AppCard(app))}</div></section>`
  const mounted = render(view)
  const icons = { '.hero-spark': SparkleGlyph, '.arrow-glyph': ArrowRightGlyph, '.box-glyph': BoxGlyph }
  Object.entries(icons).forEach(([selector, glyph]) => mounted.fragment.querySelectorAll(selector).forEach(el => el.replaceChildren(glyph({ size: 16 }))))
  mounted.fragment.querySelector('.apps-glyph')?.replaceChildren(BoxGlyph({ size: 18 }))
  mounted.fragment.querySelector('.cloud-glyph')?.replaceChildren(CloudGlyph({ size: 18 }))
  mounted.fragment.querySelector('.warning-glyph')?.replaceChildren(WarningGlyph({ size: 18 }))
  mounted.fragment.querySelector('.build-glyph')?.replaceChildren(ArrowRightGlyph({ size: 18 }))
  return mounted
}
