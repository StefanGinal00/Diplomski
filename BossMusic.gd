extends RefCounted
## Paths, not preloads: only the current encounter and outgoing fade hold music.
const TRACKS := {
	"boss_void_sentinel": "res://audio/music/bosses/void_sentinel.ogg",
	"boss_abyss_warden": "res://audio/music/bosses/abyss_warden.wav",
	"boss_echo_matriarch": "res://audio/music/bosses/echo_matriarch.ogg",
	"boss_ash_castellan": "res://audio/music/bosses/ash_castellan.ogg",
	"boss_starfall_guardian": "res://audio/music/bosses/starfall_guardian.ogg",
	"boss_hollow_sovereign": "res://audio/music/bosses/hollow_sovereign.wav",
	"boss_ember_marshal": "res://audio/music/bosses/ember_marshal.ogg",
}

static func track_for(boss_id: String) -> String:
	var key := "boss_" + boss_id
	return key if TRACKS.has(key) else "boss"

static func load_track(track_id: String) -> AudioStream:
	var stream := load(String(TRACKS[track_id])) as AudioStream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
		stream.loop_offset = 0.0
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	return stream
