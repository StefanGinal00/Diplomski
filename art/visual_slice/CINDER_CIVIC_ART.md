# Cinder civic facades — 2026-09-27

CinderCivicArt.gd adds static code-native facade accents to six existing
EasternDistricts buildings. Existing masonry/roof textures are reused; no
new bitmap generation, scene replacement, interior or gameplay service.

| Building | Identity |
| --- | --- |
| BellFoundry | Banded chimney, suspended bronze casting bell |
| CaravanInn | Half-timber framing, warm arched attic, striped canopy |
| KilnSchool | Framed chalkboard and light eave trim |
| ArchiveHall | Fluted pilasters, cornice and scroll relief |
| CopperLibrary | Rose window, arched side windows, open-book relief |
| GateBarracks | Low crenellated parapet and shield insignia |

Bounds derive from each existing facade, including translated room origins.
One cached drawing node, no children, frame processing, timers, physics or
interaction. Original polygons, visibility, actor/door/route transforms and
collision shapes are unchanged. Decorative marks remain behind actors and
walkable platforms. Existing stairs can partly cross facade ornaments; this
pass does not redesign traversal or claim finished terrain/platform art.

## Verification

13 targeted smoke tests pass (not the entire 170-script suite). The new
settlement_civic_art_smoke.gd verifies six distinct registered roles,
translated anchors, static/idempotent construction, hidden-room visibility,
and preservation of original geometry, visibility, transforms and physics.

Six 960x540 GPU views from tests/preview_cinder_civic_art.gd were reviewed:
art/characters/preview_cinder_civic_{foundry,inn,school,archive,library,barracks}.png.
They are staged desktop renders using D3D12 Forward Mobile, not mobile
profiling or a full playthrough. Saves are isolated under res://_tmp_*.

Next: improve the playable platform/terrain facing and transitions so the
architecture and walking routes share a coherent visual treatment, then
apply distinct landmark treatment to Echo services and Starfall districts.
