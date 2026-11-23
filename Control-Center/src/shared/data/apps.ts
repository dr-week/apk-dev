import type { AppRecord } from '../contracts/app'
import registry from '../../../../Apps/registry.json'

const details: Record<string, Omit<AppRecord, 'id' | 'name' | 'path'>> = {
  SMKD: { packageId: 'com.disha.donengine', category: 'Finance', version: '1.0', status: 'In development', updated: '2026-11-10', tint: 'sunset', initials: 'SM' },
  'The-Social-Base': { packageId: 'com.followdesk.app', category: 'Social', version: '0.1.0', status: 'Ready for release', updated: '2026-11-10', tint: 'violet', initials: 'SB' },
  'Dishant-CV': { packageId: 'com.dishant.cvstudio', category: 'Productivity', version: '1.0.0', status: 'In development', updated: '2026-11-10', tint: 'mint', initials: 'CV' },
}

export const registeredApps: AppRecord[] = registry.apps.map(app => ({
  ...details[app.name], id: app.name, name: app.displayName, path: app.projectPath,
}))
