import { defineConfig } from 'vite'

const root = 'C:/CODES/webframework/fast/packages'
export default defineConfig({
  resolve: { alias: {
    '@zuari/signals': `${root}/signals/src/index.ts`,
    '@zuari/dom': `${root}/dom/src/index.ts`,
    '@zuari/glyphs': `${root}/glyphs/src/index.ts`,
  } },
})
