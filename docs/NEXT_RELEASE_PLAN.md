# WildTrack — Next Release Plan

## Visual direction
- Premium naturalistic UI matching approved mockups.
- Forest green / sage / beige / ivory / earth palette.
- Large wildlife and landscape photography, dawn/dusk emphasis.
- Rounded cards, strong hierarchy, airy layouts, consistent icons.
- Main navigation: Esplora, Avvista, Diario, Community.
- App label visible to users: `WildTrack` only; no visible semantic version in launcher label.

## Core upgrades
1. Automatic Overpass fallback across multiple endpoints.
2. End-to-end encrypted chat architecture.
3. Advanced moderation: report, block, mute, anti-spam/rate limits, abuse controls.
4. Registered privacy-first accounts with minimal-data design, pseudonymous identifiers and passkey-first authentication where feasible. No ad profiling, no sale of location data, no unnecessary personal data collection.
5. Push notifications, enabled by default but independently disableable for:
   - incoming chat messages;
   - new wildlife observations.
6. Expanded diary/statistics:
   - unique species;
   - distance travelled;
   - field time;
   - observations per month;
   - most-observed species;
   - new lifers;
   - private heatmap;
   - visited regions/provinces.

## WOW features
- WildTrack Radar: observation probability based on location, season, time, weather, habitat and historical data.
- Esplora missions / field challenges.
- Automatic naturalistic field diary after outings.
- Personal biodiversity index.
- WildTrack Lens for animals, tracks, footprints, feathers, scat and field signs with confidence score and alternatives.
- Species-aware photography mode with camera-setting suggestions and ethical-distance guidance.
- Animal activity forecast.
- Nearby recent observations with precision degradation and delay for sensitive species.
- Shareable naturalistic passport without sensitive coordinates.
- Temporary private expedition groups with shared location, route, chat and sightings.
- Field Silence mode.
- Personal nature timeline based on private history.

## UX principles
- Understandable in under 10 seconds.
- Home contextual rather than menu-heavy.
- Quick sighting entry should take only a few taps.
- Maps should use one layer/filter control rather than uncontrolled marker clutter.
- Separate exploration, field-use and archive/review mental models.
- Protect sensitive wildlife coordinates by design.

## Implementation rule
Keep the current installable 0.5 main branch as the baseline. Implement work on a dedicated branch and only merge after successful Android build and smoke checks.
