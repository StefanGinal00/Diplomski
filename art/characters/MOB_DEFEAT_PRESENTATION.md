# Ordinary-mob defeat presentation

Ten actor types now retain their last painted body pose for a short 0.24 s
cosmetic fade instead of disappearing abruptly: Enemy, Ash Fiend, Root Stalker,
Shaft/Ash Sentry, Crawler, Wisp, Shade, Broodling and Ranged Enemy.

- Grounded bodies compress slightly around their registered foot origin.
- Wisp/Shade lift 4 world pixels while fading.
- A small family-specific impact uses existing animated attack atlas cells;
  heated sentries keep their own warm body material.
- Native death, hitbox removal, experience and gold are unchanged. This is a
  visual snapshot, not a new AI state, physical corpse or delayed reward.
- At most 16 mob bodies and the existing shared 64 cosmetic effects may exist.
- Room changes, rest, transitions and hiding a disabled room immediately retire
  the effects. Ordinary pause inherits normal scene processing.
- Neutral fauna is excluded.

Appearance visibility handlers also clear stored hurt/locomotion presentation
when hidden. Native AI timers remain authoritative on re-entry. Ranged enemies
now show their existing hurt cue as a painted-body tint.

No new bitmap assets were generated: this pass reuses the current body poses
and animated attack atlases. It is not a dedicated frame-by-frame death atlas.

## Verification

`tests/mob_defeat_echo_smoke.gd` covers 20 native defeats (both facings),
exact initial transforms in rotated/scaled parents, palette isolation, feet,
flying lift, immediate single native XP/gold drops, all ten hidden poses,
neutral exclusion, lifecycle cleanup, parent disposal and both effect budgets.

`tests/preview_mob_defeat.gd` renders all ten native callbacks at zoom 2.5
with disabled AI and deterministic effect time. These are presentation samples,
not full fight recordings. Native optional loot remains visible in the gallery.

- [Before](preview_mob_defeat_before.png)
- [Immediate contact](preview_mob_defeat_0.png)
- [85 ms](preview_mob_defeat_1.png)
- [170 ms](preview_mob_defeat_2.png)
- [255 ms / cleared](preview_mob_defeat_3.png)

Before, contact, 85 ms and cleared captures visually inspected. Feet stay
registered and both flying bodies lift without leaving permanent sprites.
Preview succeeded on D3D12 with an explicit workspace log file. Initial launch
without that override crashed while opening the restricted user log; rerun
completed all five captures. Known host certificate/shader-cache warnings
remain; no project script/shader compilation errors occurred in the rerun.

See `tests/LATEST_SMOKE_RESULTS.md` for the 15 passing focused tests and reports.
