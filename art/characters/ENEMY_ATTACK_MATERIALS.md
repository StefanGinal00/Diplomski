# Enemy attack textures - 2026-09-28

Update: the following single-texture checkpoint has been superseded at runtime
by [actual six-frame combat flipbooks](COMBAT_FLIPBOOKS.md). The v1 atlas remains
as source/reference and for older material-coverage tests.

This pass adds painted attack materials, not just new body poses. It does not
declare the entire game's art or every spell's frame-by-frame animation finished.

## Saved art and provenance

- Production: [enemy_attacks_v1.png](enemy_attacks_v1.png), 1280x1600 RGBA,
  20 isolated 320px cells, mipmaps enabled, transparent gutters.
- [Exact prompts and source inventory](drafts/enemy_attack_prompts_v1.json).
- Generated using the **imagegen skill and built-in image_gen**, two calls.
  Both generated sources are 1254x1254 RGBA (not the requested 2048); no alpha
  removal or fabricated resolution claim. Originals remain in `drafts/` and the
  tool's generated-images directory. Drafts are excluded from Godot import.
- `tests/prepare_attack_atlas.py` preserves alpha, pads/normalizes the cells and
  emits `EnemyAttackBounds.gd` for floor-aligned tight rendering.

## Connected attacks

| Actor | Painted material / actual trigger |
| --- | --- |
| Void Sentinel | Fractured violet crystal bolt and impact |
| Abyss Warden | Cyan abyss lance and impact |
| Echo Matriarch | Resonant magenta rings, bolts and release |
| Ash Castellan | Burning coal bolts and grounded fire eruptions |
| Hollow Sovereign | Spectral souls, runic bursts and starfall columns |
| Starfall Guardian | Four-point celestial bolts and blue pulse columns |
| Ember Marshal | Molten iron bolt and impact |
| RangedEnemy | Crimson thorn dart and successful-shot muzzle flash |
| ShaftSentry / AshSentry | Crystal needle / horizontal flame; tier aura preserved |
| Enemy / AshFiend | Ivory contact claws / ember contact claws |
| NeutralCreature | Leaf-edged contact scratches only after becoming hostile |
| ShaftCrawler | Chitin/stone scrape on charge and contact |
| ShaftWisp | Wing-like slipstream during committed dive and contact |
| EchoShade | Spectral wake during native dash and contact |
| EchoBroodling | Teal chitin leap wake and contact |
| RootStalker | Bark/root eruption fitted to the native StrikeArea during burst |

Native warning icons, lines and timing remain authoritative. Painted material
does not define damage. Contact flashes indicate an attempted contact, not proof
that an invulnerable player lost HP. Friendly NPCs receive no attack effects.
Inherited scene variants reuse their archetype material; this is not a unique
hand-painted animation for each individual spawn.

## Runtime and boundaries

`EnemyAttackArt.gd` shares one imported atlas. `BossProjectileAppearance.gd`
now handles normal shooters as well as bosses. The bright head is aligned with
the unchanged radius-4 collider, with restrained trails and a small readable core.
`MobAttackPresentation.gd` observes native state after physics. It clears on hide
and does not own damage, targeting, cadence, loot or RNG. Root strikes use the
actual rectangular shape dimensions. Ground bursts register the dense painted
base (alpha above 120/255), excluding padding and faint low particles that
otherwise make the visible column float above the floor. Source alpha is intact.

Textured bursts expand/fade; flight textures pulse and trails follow committed
direction. These are animated texture transforms, **not new multi-frame attack
flipbooks**. Existing 12-frame boss body sequences remain separate. Thin native
boundary cues remain, while thick procedural pillar scaffolding is removed from
painted bursts. Finite effects expire and share a 64-effect cosmetic budget;
room processing/streaming inheritance is preserved.

## Verification

11/11 focused smoke tests passed: `enemy_attack_art`, `ranged_attack_cue`,
`boss_combat_presentation`, `shaft_zone`, `starfall_empty_court`,
`neutral_creatures`, `starfall_rooted_hall`, `shaft_ranged_combat`,
`sentinel_combat_flow`, `echo_grotto`, `ash_arena`.

New test covers all 20 distinct nonempty alpha cells, mipmaps, bounded alpha
regions, eight contact archetypes, both sentry variants and the normal shooter,
native three-shot tier fan, unchanged health/colliders, passive neutrality,
hidden-room resets and cosmetic budget/expiry. Existing boss regression checks
all seven actors, all release families, projectile identity and cleanup.

D3D12 gallery and scripted Ash Castellan / Hollow Sovereign / Echo Matriarch
arena renders inspected. Preview logs have the known host certificate warning;
full-arena rendering also reports host shader-cache write warnings. No project
script errors. Full repository suite, export and manual full fight not run.

Next: author multi-frame VFX sequences for priority attacks, then playtest
readability at normal zoom and dense encounter pacing. Do not lengthen damage
windows merely to accommodate an animation.
