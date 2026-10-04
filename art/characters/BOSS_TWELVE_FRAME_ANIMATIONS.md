# Twelve-frame boss animation sets - 2026-09-28

All seven painted encounter actors now use **12 actual painted frames each**
(84 total), replacing the active four-pose body presentation. The original v1
images remain untouched as references and a fallback. No combat damage,
collision shapes, attack timers, rewards or rematch rules were changed here.

## Saved production atlases

- [Void Sentinel](boss_void_sentinel_animation_v2.png): six walking poses and
  chest-core anticipation, release and settling.
- [Abyss Warden](boss_abyss_warden_animation_v2.png): heavy steps, braced shoulder
  rush and recovery.
- [Echo Matriarch](boss_echo_matriarch_animation_v2.png): six wingbeat poses,
  folded-wing preparation and spread-wing release. Wingbeats continue while
  hovering in place; the flying body is not grounded like the knights.
- [Ash Castellan](boss_ash_castellan_animation_v2.png): armored steps with cape
  lag, fist/shoulder anticipation, strike and recovery.
- [Hollow Sovereign](boss_hollow_sovereign_animation_v2.png): mantle motion,
  gathered hands, reaching cast and settling.
- [Starfall Guardian](boss_starfall_guardian_animation_v2.png): articulated
  mechanical steps, chest preparation and reaching release.
- [Ember Marshal](boss_ember_marshal_animation_v2.png): mace-carrying steps,
  windup, swing and lowered-weapon follow-through.

Each sheet is four columns by three rows: idle (0), locomotion (1-6), early/late
anticipation (7-8), release or sustained charge (9), follow-through (10),
settled recovery (11). The sets are shared across each actor's attacks, not
separate twelve-frame sheets for every individual spell. Distinct spell VFX,
floor warnings, phase effects and rematch auras continue to supply those cues.

## Generation and local processing

New artwork was generated with built-in `image_gen`, one request per actor
sheet, using each original boss sheet as an identity reference. Sentinel's
two earlier six-frame candidates were reused. No API/CLI generation was used.
The user explicitly approved local background extraction after the generator
returned baked checkerboards rather than real alpha.

Exact prompt set: [six additional actors](drafts/boss_animation_prompts.json),
[Sentinel prompts and failed alpha attempts](drafts/SENTINEL_TWELVE_FRAMES.md).
Exact source inventory and frame order:
[manifest](drafts/boss_animation_sources.json). Original generated files are
retained under `drafts/`, which is excluded from Godot import using `.gdignore`.

`tests/prepare_boss_frames.py` uses Pillow for approved local processing:
green-key removal or exterior neutral-checker extraction; enclosed checker
pocket cleanup while preserving enclosed pale highlights; connected-component
slicing so an extended hand is not chopped at a nominal grid edge; common
actor scale and registered pivots; RGBA atlas assembly. No character redraw,
new animation synthesis or opaque-background runtime shader is used.

Most atlases are 2048 x 1344; Matriarch has wider cells (2840 x 1344) to retain
wingtips. Idle silhouettes normalize to 300 source pixels high, with one scale
per actor so crouches are not stretched back to standing height. Runtime scale
keeps the previous actor height. Grounded feet use a common baseline; the
Matriarch uses a hover pivot. Mipmaps are enabled on every production texture.
The RGB draft checkerboards/green screens are **not** gameplay textures.

Reproduce approved local processing from the project root:

```powershell
python tests/prepare_boss_frames.py art/characters/drafts/boss_animation_sources.json
```

Per-frame bounds are recorded beside the PNGs as JSON and compiled into
`BossFrameData.gd`; runtime does not depend on loose JSON being exported.
Texture loading is per instantiated actor. Legacy texture references are
lazy fallback paths, rather than preloading both old and new atlas batches.
No exported application was built in this pass.

## Runtime integration

`BossFrameSequence.gd` chooses frames using traveled distance for ground
locomotion, time for wingbeats, and authoritative windup/recovery timers.
`BossAppearance.gd` distinguishes semantic `pose_index` from atlas `frame`.
The release hook displays frame 9 on the same physics tick as the attack,
without crossfading away the strike. Existing short pose blends, hurt tint,
committed charge facing and high-FPS stride continuity remain in place.

The isolation shader now accepts the atlas grid. Charge afterimages and death
echoes use the current texture, frame grid and per-frame bounds, so they no
longer assume a two-by-two sheet. Hidden actors reset animation-only timers.

## Verification and scope

**12/12 focused smoke tests pass**; full repository suite was not run.
[Accepted reports](../../tests/LATEST_SMOKE_RESULTS.md).
The new `boss_frame_sequence_smoke.gd` checks seven actors and 84 unique,
nonempty alpha frames, six locomotion phases, anticipation progression,
same-tick release, follow-through, recovery, reset and unchanged gameplay data.
Existing appearance/motion/presentation tests were updated to distinguish
semantic poses from the expanded frame indices; collision tests retain the
Marshal's original `mini_boss` group.

Godot D3D12 rendered a twelve-stage registration gallery and a real scripted
Sentinel approach/brake/cast/dodge/turn sequence. Reviewed examples:
[locomotion](preview_boss_extended_03.png),
[anticipation](preview_boss_extended_08.png),
[release](preview_boss_extended_09.png),
[Sentinel windup in arena](preview_sentinel_flow_windup.png).
The Warden's actual controller was also stepped through eight captures:
anticipation frames 7/8, sustained charge frame 9 with updated afterimages,
and recovery frames 10/11. [Reviewed charge](preview_boss_motion_060.png).
The preview environment reports its existing root-certificate and shader-cache
write warnings; captures complete successfully. These are scripted previews,
not a full manual playthrough of every encounter.

The sets add real intermediate painted poses, but are not skeletal animation
or a large hand-authored frame-by-frame production. Generated designs still
have modest pose/proportion variation. Per-spell unique body sequences, new
hurt/death sheets and further playtest-driven gait refinement remain future
polish, rather than being claimed finished by this twelve-frame pass.
