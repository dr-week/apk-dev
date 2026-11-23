import { createSvgElement } from '@zuari/glyphs'

export const ArrowRightGlyph = (props = {}) => createSvgElement('0 0 24 24', '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>', props)
export const BoxGlyph = (props = {}) => createSvgElement('0 0 24 24', '<path d="m12 3 9 5-9 5-9-5 9-5Z"/><path d="M3 8v9l9 5 9-5V8"/><path d="M12 13v9"/>', props)
export const CloudGlyph = (props = {}) => createSvgElement('0 0 24 24', '<path d="M20 16.2A4.8 4.8 0 0 0 18 7h-1.2A7 7 0 1 0 4 16.2"/><path d="M12 12v9m-4-4 4-4 4 4"/>', props)
export const WarningGlyph = (props = {}) => createSvgElement('0 0 24 24', '<path d="m10.3 4.3-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.7-2.7l-8-14a2 2 0 0 0-3.4 0Z"/><path d="M12 9v4m0 4h.01"/>', props)
