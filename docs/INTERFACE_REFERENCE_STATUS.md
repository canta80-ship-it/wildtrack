# Interface reference implementation — 1 October 2026

The ten attached mockups are the visual contract. Production must use live Flutter controls and actual user data, not whole-screen screenshots or fabricated activity.

Implemented in this change:
- Replace the broken approved artwork archive with a verified asset archive extracted from the supplied references.
- Use the approved deer, roe deer, fox and buzzard thumbnails in four responsive Home columns.
- Replace the shared synthetic landscape/animal painters with bundled approved artwork.
- Use real binocular icons, not eye icons.
- Match Home, access, welcome, species, sighting, permission, diary and Community geometry more closely to the reference.
- Preserve the four main destinations and visible labels.
- Restore native camera/gallery controls, photo removal and both private/public save actions in the reference composition.
- Validate archive integrity and required assets in every CI build.

NOT YET CERTIFIED:
- Pixel identity with all ten references on the installed Android APK.
- Full landscape artwork hidden behind text in the supplied mockups is unavailable. The clean visible landscape was extracted; full-screen source artwork is not recreated or claimed identical.
- Editorial titles now use bundled Libre Baskerville regular/bold/italic, rather than an unresolved Android serif alias. The original mockup font remains unidentified, so exact typeface equality is not claimed. Font license is bundled with the app.
- All 24 species now have individual generated naturalistic hero images, bundled at 1536×1024, and an explicit record of four signs, four seasonal notes, habitat tags and photo advice. These new illustrations follow the deer reference; they are not claimed to be identical original artwork.
- Signs beyond the deer use native foot schematics and icons; matching naturalistic illustrations for every sign remain incomplete.
- National conservation categories are displayed only where checked against a species source; remaining cards display species ecology and link the source rather than assigning a false LC category.
- Live cartographic tiles and live chat/account data necessarily depend on current state. The frame and controls must match the reference; dates, names, counters and coordinates remain real data.

Do not present a successful build as proof of visual equality. Capture the exact compiled APK before claiming compliance.
