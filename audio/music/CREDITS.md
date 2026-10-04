# Boss music credits

Retrieved 2026-09-29 from the individual OpenGameArt submissions below.
Each submission lists **CC0 1.0 Universal**:
<https://creativecommons.org/publicdomain/zero/1.0/>.
These are third-party, non-exclusive tracks, distinct for each encounter in this
game; they are not original compositions commissioned for this project.
Voluntary attribution is retained here alongside the source and original filename.

| Encounter / local file in `bosses/` | Track / creator | Source | Original download filename |
| --- | --- | --- | --- |
| Void Sentinel / `void_sentinel.ogg` | Battle RPG Theme (variation), Cleyton Kauffman | [Boss Battle Theme](https://opengameart.org/content/boss-battle-theme) | `CleytonRX - Battle RPG Theme Var_0.ogg` |
| Abyss Warden / `abyss_warden.wav` | Determined Pursuit, Emma_MA | [Determined Pursuit](https://opengameart.org/content/determined-pursuit-epic-orchestra-loop) | `determined_pursuit_loop.wav` |
| Echo Matriarch / `echo_matriarch.ogg` | Fairy Boss Battles, MintoDog | [Fairy Boss Battles](https://opengameart.org/content/fairy-boss-battles) | `fairy_boss_battles_bpm185_0.ogg` |
| Ash Castellan / `ash_castellan.ogg` | Heat Boss Battle, MintoDog | [Heat Boss Battle](https://opengameart.org/content/heat-boss-battle) | `heat_boss_battle_bpm165_0.ogg` |
| Starfall Guardian / `starfall_guardian.ogg` | Hope (Orchestral Battle Music), MintoDog | [Hope](https://opengameart.org/content/hopeorchestral-battle-music) | `hope_orchestral_battle_music_bpm165_0.ogg` |
| Hollow Sovereign / `hollow_sovereign.wav` | Epic Boss Battle, Juhani Junkala (SubspaceAudio) | [Boss Battle Music](https://opengameart.org/content/boss-battle-music) | `Juhani Junkala - Epic Boss Battle [Seamlessly Looping].wav` |
| Ember Marshal / `ember_marshal.ogg` | Heavy Battle 2, MintoDog | [Heavy Battle 2](https://opengameart.org/content/heavy-battle-2) | `heavy_battle_2_bpm185_0.ogg` |

Cleyton's requested credit: Music by Cleyton Kauffman —
<https://soundcloud.com/cleytonkauffman>.

## Integration

Downloads are unmodified apart from local filenames. Godot imports the audio;
`BossMusic.gd` enables full-track loops. The soundscape applies -20 dB playback
gain and a 1.2-second ambient/battle crossfade. No tempo or pitch change on rematches.
Only the incoming/outgoing encounter streams are held, not a seven-track preload.
Mute, interruption, room exit and victory release the outgoing stream.
The Marshal theme begins in the arena's final wave, not during ordinary waves.
Existing procedural room ambience and the post-Sovereign finale remain separate.
WAV imports use Godot's default QOA compression (`compress/mode=2`); original
WAVs are retained for reproducible imports. Five other tracks use Ogg Vorbis.

Selection is based on the authors' instrumentation/loop descriptions: orchestral
guardians, fantastical Echo combat, heavier forge/arena fights, full orchestral
finale encounter. An in-game listening pass remains necessary for loudness and
musical fit against attack sounds; automated asset checks are not a listening test.

## Download SHA-256

```text
E4F3BE098B50213B56A60AEFE60FFFAE79CD9F7C9008088F93C187EF1BBC856B  abyss_warden.wav
2D3DF5F1D65DE4C487C970E74D01779CD162290D1DA83696D7453ADCA9F52A6C  ash_castellan.ogg
1FB96B3C4F58A88C6EE1EB9D47EF91D251AE118DCEADA5C2E0C37B8B86FDC42E  echo_matriarch.ogg
01D3D505139161A04B3F225AD9CDC0ACB52A8E21C997E658C916173DEF647DF8  ember_marshal.ogg
35F75B4381DFBB053992876F7DFC567D9FD959D61B73954D5B1CD519753E7DF1  hollow_sovereign.wav
1615903236286AF59D14B4D71DA3FC2518A3091ECDD8F162A50215B9B3D0F320  starfall_guardian.ogg
9A63F74305F5CBCE8374A72A027A645C07C97663255ABA0B817BC1F70C432ED5  void_sentinel.ogg
```
