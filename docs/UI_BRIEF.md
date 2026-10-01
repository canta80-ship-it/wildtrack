# WildTrack — UI/UX & Brand Brief

This document is the visual source of truth for the next release.

## Product feeling
WildTrack must feel premium, naturalistic, calm, modern and immediately usable in the field. It must not look like a GIS tool, a generic social network or a dense settings dashboard.

## Visual language
- Forest green primary: `#254D38`
- Sage: `#DDE8DA`
- Ivory / cream: `#F8F6EF`, `#F3F0E7`
- Earth / beige: `#EADCC8`
- Natural brown accents: `#765239`
- Large wildlife and landscape photography, especially dawn, dusk, forests and mountains.
- Rounded cards, typically 18–28 px visual radius.
- Generous whitespace and large touch targets.
- Strong hierarchy: editorial-feeling headings plus highly legible UI text.
- Simple nature/outdoor icons: paw, binoculars, trails, GPS, camera, feather, footprint, diary, radar, community.
- No visible release number in launcher label. User-facing name is always `WildTrack`.

## Main navigation
Exactly four persistent destinations:
1. **Esplora** — contextual home, map, trails, Radar, nearby species and field planning.
2. **Avvista** — fast sighting entry: animal, footprint/track, feather/remains, unknown/Lens.
3. **Diario** — outings, unique species, distance, field time, monthly observations, most-observed species, lifers, private heatmap, regions/provinces, naturalistic passport.
4. **Community** — public observations, encrypted chats, private groups/expeditions and moderation.

## Home / Esplora
The home should be understandable within 10 seconds. Preferred structure:
- WildTrack brand row and settings/notification controls.
- Contextual greeting.
- Activity card with wildlife activity level and useful dawn/dusk context.
- Three dominant actions: `Esplora zona`, `Registra avvistamento`, `Avvia uscita`.
- WildTrack Radar preview.
- Likely species / nearby nature content.
- Last outing and diary preview when data exists.

## Map
- Clean nature-focused basemap.
- One unified layers control instead of many independent buttons.
- Filters: Sentieri, Specie, Community, Radar.
- Sensitive wildlife coordinates are always degraded/delayed by design.
- Overpass calls use automatic provider fallback.

## Quick sighting
Start with four large choices:
- Animale
- Impronta / traccia
- Penna / resto
- Non so, aiutami

Then reveal only what is needed: photo, species, count, position, notes and privacy. Advanced fields must never block a fast save.

## Species detail
Photo-led hero followed by concise cards for habitat, status, size, signs/footprints, best season, calls, behavior and photography advice.

## Diary
Use a premium dashboard rather than a text list. Required metrics:
- unique species
- km travelled
- field time
- total and monthly observations
- most-observed species
- new lifers
- private heatmap
- visited regions/provinces
- latest outings
- personal biodiversity index
- nature timeline

## Community
Use safe, calm chat/group UI. Reporting, blocking, muting and moderation must always be reachable. Never automatically expose exact sensitive wildlife coordinates.

## Private expeditions
Temporary groups can share position, route, messages and observations. Expiry must be explicit and sharing must stop automatically at the end.

## Privacy
Data minimization by design. No ad profiling, no selling location data and no collection of unnecessary identity data. Registration should be pseudonymous/passkey-first where technically feasible. Explain precisely what is stored; never claim “no data is collected” if technical account data exists.

## Field Silence mode
Darkened, low-distraction field interface with no unnecessary sounds, reduced visual brightness, large controls and rapid access to GPS/sighting actions.

## Consistency rule
Every future screen must reuse the same palette, radii, icon language, spacing, typography hierarchy and photographic direction. A new feature must never look as if it came from a different app.
