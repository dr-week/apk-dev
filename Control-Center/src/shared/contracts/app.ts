export type StoreStatus = 'In development' | 'Ready for release' | 'Published'
export type AppRecord = {
  id: string; name: string; packageId: string; path: string; category: string
  version: string; status: StoreStatus; updated: string; tint: string; initials: string
}
