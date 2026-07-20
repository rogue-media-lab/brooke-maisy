# Brooke & Maisy — Brand Guide

> Extracted from live site + Tailwind v4 `@theme` config on 2026-07-08.
> Authoritative source of truth: `app/assets/tailwind/application.css`

---

## Color Palette

### Primary Brand Colors

| Token | Hex | Swatch | Role |
|---|---|---|---|
| `theme-100` | `#F7F4EF` | ████████ | Ivory/off-white — page backgrounds, navbar, hero gradient start |
| `theme-200` | `#E7DED1` | ████████ | Light beige — secondary CTA buttons, hover states on dark backgrounds |
| `theme-300` | `#C8B8A8` | ████████ | Medium taupe — hero gradient end, image frame borders |
| `theme-400` | `#BDA59E` | ████████ | Soft mauve-brown — accent color (star ratings, admin links, hover text) |
| `theme-500` | `#776B63` | ████████ | **Dark warm brown — PRIMARY BRAND COLOR.** Headings, CTA buttons, footer, nav links |

### Neutral Palette

Only these non-theme colors are permitted across the site:

| Color | Typical Use |
|---|---|
| `white` | Card backgrounds, button text on dark backgrounds, portfolio section background |
| `black` | Overlay backgrounds (lightbox backdrop) |
| `gray-50` | Mobile menu background, subtle section backgrounds |
| `gray-100` | Icon container backgrounds, nav link hover states |
| `gray-200` | Image placeholders, navbar bottom border |
| `gray-300` | Default form input borders |
| `gray-400` | Subtle labels (trade type badges like "PAINTER") |
| `gray-500` | SVG icons in service cards |
| `gray-600` | Body/description paragraph text |
| `gray-700` | Nav links (default state) |
| `gray-800` | Footer top divider |
| `gray-900` | Hero body text, footer CTA button text |

**No other custom palettes are permitted.** The following were migrated to `theme-*` and must not reappear: `olive-*`, `navy-*`, `emerald-*`, `ivory-*`, `cream-*`, `pastel-*`.

---

## Typography

| Role | Font Stack | CSS Variable |
|---|---|---|
| Display / Headings | Playfair Display, serif | `--font-display` |
| Body / UI | Inter, ui-sans-serif, system-ui, sans-serif | `--font-sans` |

**Usage rules:**
- `font-display` class: brand/logo text in footer
- `font-sans` class: implicit default for all body, nav, and UI text
- Headings: `font-semibold` with tight letter-spacing (`-1px` to `-1.5px`)
- Body text: `text-lg` or `text-base`, `leading-relaxed`

---

## Color Application Reference

### By Element

| Element | Background | Text Color | Border / Shadow |
|---|---|---|---|
| Page body / sections | `theme-100` or `white` | — | — |
| Navbar | `theme-100` | `gray-700` (links) | `border-b border-gray-200` |
| Dark CTA button | `theme-500` | `white` | none |
| Dark CTA button (hover) | `theme-200` | `theme-400` or `theme-500` | none |
| Light/outline CTA button | `white` | `theme-500` | `border border-theme-500` |
| Light CTA button (hover) | `theme-200` | — | — |
| Footer | `theme-500` | `white` | `border-t border-gray-800` |
| Card | `white` | `theme-500` (title) / `gray-600` (body) | `shadow-sm` |
| Hero section | gradient `theme-100 → theme-300` | `theme-500` (h1) / `gray-900` (p) | — |
| Star ratings / accent | — | `theme-400` | — |
| Form inputs | `white` | `gray-900` | `border-gray-300` → `border-theme-500` (focus) |
| Mid-page CTA section | `theme-500` | `white` (heading/body) | — |
| Mid-page CTA button | `theme-200` | `gray-900` | none |
| Mid-page CTA button (hover) | `theme-100` | — | — |

### Hero Image Frame

```
┌─ border-4 border-theme-300 p-1 bg-white shadow-xl rounded-xl ─┐
│  ┌─ rounded-lg overflow-hidden ─────────────────────────────┐  │
│  │  image (object-cover)                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Animations

| Name | Duration | Easing | Effect |
|---|---|---|---|
| `animate-fade-in` | 0.5s | ease-in-out | opacity 0 → 1 |
| `animate-slide-up` | 0.3s | ease-out | translateY(10px) → 0 + opacity 0 → 1 |

---

## Do's and Don'ts

**Do:**
- Use `theme-100` through `theme-500` for all brand color needs
- Use `white`, `black`, and `gray-50` through `gray-900` for neutrals
- Use Tailwind arbitrary values (`bg-[#...]`) ONLY for dynamic colors (e.g., color swatch previews from DB)
- Keep the brown theme warm and cohesive — all five tokens work as a system

**Don't:**
- Introduce new named color palettes (no `brand-*`, `accent-*`, etc.)
- Use inline styles except for dynamic hex values from the database
- Use `olive-*`, `navy-*`, `emerald-*`, `ivory-*`, `cream-*`, or `pastel-*` — these were purged
- Mix in Tailwind's `amber`, `yellow`, `rose`, or other hue families as functional colors

---

## Source Files

- `app/assets/tailwind/application.css` — `@theme` block (canonical color definitions)
- `app/views/shared/_navbar.html.erb` — navbar styling
- `app/views/shared/_footer.html.erb` — footer styling
- `app/views/pages/home.html.erb` — hero, sections, CTAs
- `app/views/layouts/application.html.erb` — base layout