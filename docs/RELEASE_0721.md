# WildTrack 0.7.21

Approved scope: photo/file attachments in private chat, sage/ivory message bubbles,
sound and vibration notifications, removal of Garmin linking, GPX import into
Lista uscite and statistics, name/description/photo editing, premium Radar map.

Radar uses rounded display boundaries over real OpenStreetMap habitat geometry.
Shared ivory/sage tile styling is applied to the existing maps; single-species habitat maps use the same rounded, dashed treatment.
The original geometry remains unchanged for habitat/route matching. Sage areas
and circular species thumbnails mean possible presence; amber photo pins and
clock badges mean recent public community reports. No report is manufactured
from a habitat match. Seasonal profiles are suggestions, not calibrated chances.
Localized/alpine species require a nearby recent report before map suggestion.
Recent reports are limited to public feed pages loaded (up to 20 pages), valid
coordinates, the selected radius, and the last seven days. Approximate locations
keep their privacy radius. The source and date appear in the report sheet.
Search filters species layers; refresh clears obsolete areas, loads both sources
independently, redraws, and frames results. Errors and empty results are explicit.
The radius can expand to 10 km. Track Radar covers habitats intersecting GPX
segments inside 10 km from its beginning; disconnected segments are never joined.

Imported GPX contributes distance, ascent/descent, outing count, and duration when
all source timestamps are usable. Files without timestamps have zero recorded
duration; duration is never guessed. XML entities and invalid coordinates are
rejected. Attachments are limited to 5 MiB and fetched only by chat participants.
The server changes have been deployed and attachment authorization tests passed.

Validation status: Python Android-generator syntax and generation on a minimal Flutter Android fixture verified; database migration
and server attachment checks passed earlier. New Dart tests cover segment gaps,
XML parsing, report filtering, season/local range constraints, rounded geometry,
route intersections, and narrow-screen Radar controls. Flutter tests, analyzer,
APK compilation/signature checks, and actual screenshot comparison remain pending:
two previous GitHub Actions runs failed before any step started. No new verified
APK has been produced. Background alerts use periodic Android checks unless the
existing Firebase push credentials are configured; immediate background delivery
is therefore not guaranteed. Notification vibration respects Do Not Disturb and
an explicitly muted Android message channel.
