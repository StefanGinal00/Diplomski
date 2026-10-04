# Boss combat presentation - 2026-09-28

## Delivered

Seven encounter actors: Void Sentinel, Abyss Warden, Echo Matriarch, Ash Castellan,
Hollow Sovereign, Starfall Guardian and arena miniboss Ember Marshal.

- Four authored key poses plus time-based breathing, stride, anticipation, charge
  lean, recovery and hit flash. This is key-pose/transform animation, not a full
  hand-drawn frame-by-frame animation set.
- Charge facing follows committed attack direction, not a player crossing behind.
- Feet are registered per pose; per-frame rendering masks remove detached fragments
  from adjacent cells. Source image pixels are unchanged.
- Release effects are invoked on the original attack physics tick. Projectile
  collision radius, damage, speed, attack cadence and reward authority unchanged.
- Bounded four-sample charge afterimages, launch/braking rings, muzzle flashes,
  themed bolt trails/impacts, resonance rings and floor/column eruption ribbons.
- Existing hazard markers keep their visibility/position authority; animated
  outlines clarify lane edges, directions, nova radius and locked-point radius.
- Phase-change ring, subtle phase aura and 0.55-second cosmetic death echo;
  actual enemy removal and rewards still happen immediately.
- Awakened aura/tint for existing Warden, Matriarch and Castellan rematches,
  and higher-tier Ember Marshal. No new NG+ or Starfall replay unlock system.
- Seven arenas have small painted relics, visible in the editor and persistent
  after victory. No collision or backdrop layers added. Obsolete geometric
  decoration retired in Resonance Sanctum, Castellan Throne, Warden arena and
  Ash Coliseum; gameplay marker geometry is retained.
- Relic redraws are capped at 24 Hz and sleep while hidden; cosmetic effects
  have finite lifetimes and follow existing room processing/visibility.

## New raster assets / provenance

Built-in imagegen skill/tool, not CLI. Generated alpha PNGs copied intact from
the generated_images session directory into the project. Mipmaps enabled.
No downloaded third-party assets, pixel retouching or source upscaling.

| Asset | Native size | Use |
| --- | --- | --- |
| [Ember Marshal](boss_ember_marshal_v1.png) | 1254 x 1254 | four isolated poses |
| [Arena relic atlas](../visual_slice/boss_arena_relics_v1.png) | 1295 x 1214 | brazier, crystal, drowned seal, astral monument |

Sources: exec-271b8a0a-0a7e-4a7b-8165-e8e6ce7541ef.png and
exec-7f8fe4e8-f8dc-4c8b-a31b-4f42ffb6a3d7.png.

### Exact Ember Marshal prompt

Use case: stylized-concept. Asset type: transparent 2D game character sprite sheet. Create Ember Marshal, a compact dark fantasy arena champion in scorched iron armor, asymmetrical bronze shoulder, closed furnace visor glowing amber, ragged burgundy tabard, small heavy mace. Hand-painted crisp 2D side-view game art, no 3D render. Four full body poses in an exact 2 by 2 equal grid on genuinely transparent alpha background: upper left idle facing right; upper right stepping forward right; lower left crouched anticipating a shoulder charge to right; lower right exhausted recovery with mace lowered. Same character size and foot baseline within each cell. CRITICAL each complete figure AND weapon occupies only central 60 percent width and central 75 percent height of its own quadrant; wide transparent padding around EVERY pose, NOTHING crossing cell borders, no particles detached from body, no shadows under feet, no ground, no text, no borders. Strong readable silhouette, subdued dark iron with small amber highlights. Orthographic flat side-view, all four looking right.

### Exact arena relic prompt

Use case: stylized-concept. Asset type: transparent 2D side-view dark fantasy game prop atlas. Exact 2x2 equal grid containing FOUR DIFFERENT freestanding small arena relics: upper left antique scorched bronze floor brazier with engraved legs and small amber flame; upper right violet resonant mineral cluster mounted in weathered carved stone bowl; lower left ancient drowned teal pressure-seal monument, corroded round wheel held by carved dark stone pedestal; lower right elegant narrow ivory and dark purple broken astronomical obelisk with a small glowing blue star in its circular crown. Hand-painted detailed 2D game art, side elevation not top-down, same grounded foot baseline per cell. Each COMPLETE object fills only central 60 percent width and central 70 percent height of its cell. Generous clear transparent margins, every cell fully isolated, no crossing borders. True alpha transparent background. No characters, floor planes, shadows outside object, text, labels, borders, grids, or watermarks. Subdued weathered material, glowing accents small, crisp silhouette at small in-game scale.

## Verification

New deterministic test: tests/boss_combat_presentation_smoke.gd.
Checks all seven actors, attack release hooks, committed facing, mirrored pivots,
recovery pose, unchanged collision authority, projectile art, bounded trails,
effect lifetimes, immediate combat cleanup and existing rematch consent/aura.
Existing encounter tests cover actual damage patterns, progression and rollback.
See tests/LATEST_SMOKE_RESULTS.md for accepted reports.

GPU previews: tests/preview_boss_combat.gd and tests/preview_boss_appearances.gd.
Nine in-world captures cover warning/release/aura for Castellan, Sovereign and
Matriarch; gallery covers seven idle/recovery pairs. Previews hold simulation
for inspection and do not substitute for manual full-fight playtesting.
Runtime warnings for restricted host certificate/shader-cache access were
observed; no combat script or shader-compilation errors in final captures.
