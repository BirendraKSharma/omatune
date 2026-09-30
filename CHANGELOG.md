# Changelog

All notable changes are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-09-30

### Added
- Search suggestions: YouTube completions appear while typing (from two
  characters), picked with `↓` / `↑`, searched with `enter`, completed with
  `tab`. Failures stay silent so typing never breaks.
- Mute toggle: `m` in the panel, a speaker button in the transport row, and
  the `toggleMute` IPC command. The now-playing header shows MUTED, so a mute
  set from media keys or the media widget is visible. Watches both of mpv's
  mute properties (`mute` and `ao-mute`) and clears both when unmuting.

## [0.2.0] - 2026-09-28

### Added
- Search history: the last 50 searches are remembered, newest first. Press
  `enter` on one to search again, `x` to forget it, or use **CLEAR HISTORY**
  to delete all of them. Turn it off with the `saveHistory` setting.
- Resumable queue: the queue (up to 200 songs), its position and the playback
  second are saved as you listen and restored after a restart. Nothing
  autoplays; press play to resume where you left off.
- Offline song cache: songs you listen to for 20 seconds are saved in the
  background with `yt-dlp` (one at a time, 5-minute / 60 MB cap, verified as
  real audio) and played from disk when available. The **Cached** list shows
  what is saved with its size, and the cache never grows past `cacheLimitMB`
  (default 1024 MB, oldest songs go first). Turn it off with `cacheSongs`.
- `ytm-store` Python helper: the only writer for `history.json`,
  `queue.json` and the cached audio, with 0700 folders and 0600 files under
  `~/.local/state/codydon-omatune/` and `~/.cache/codydon-omatune/audio/`.
- Settings: `saveHistory`, `cacheSongs`, `cacheLimitMB`.
- Panel views: Results, Queue, Cached and History with `q` to cycle, `1`-`4`
  to jump, and a two-click confirm for **CLEAR HISTORY** and
  **CLEAR OFFLINE SONGS**. Songs that will play from disk are marked 󰇚.

### Changed
- Nothing extra to install on Omarchy: `mpv`, `yt-dlp`, `mpv-mpris`, `curl`,
  `jq` and `python` all ship with it. `deno` is now optional (it lets yt-dlp
  solve YouTube's JavaScript challenges).
- Queue view shows the saved queue after a restart, with a header saying
  where it will resume.
- Troubleshooting and **Remove** docs cover the two data folders and what
  stays behind after removing the plugin.

## [0.1.1] - 2026-09-24

Hardening for the Omarchy plugin marketplace.

### Changed
- mpv is now a child process owned by the plugin instead of a detached
  player, so it stops when the plugin is disabled or removed, or when the
  shell exits. Music no longer continues across a full shell restart.
- mpv runs with `--no-config`, so a personal `mpv.conf` can't change how the
  plugin plays or loads scripts; `mpv-mpris` is loaded explicitly.
- Helper processes run under `timeout -k`, which kills the whole process
  group at the deadline, with a minimal environment and a byte-counted
  output reader.
- The `search` and `playResult` IPC methods bound their input the same way
  the panel does.

### Removed
- The mpv log and pid files. OmaTune now writes only its control socket.
- The `start` and `stop` backend commands (replaced by `player`).

## [0.1.0] - 2026-09-24

### Added
- Account-free YouTube Music search through the anonymous InnerTube
  `WEB_REMIX` client.
- Song radio: picking a song plays it and queues up to 40 related songs.
- Playback through mpv and yt-dlp.
- Bar widget with the current title; click, middle-click, right-click and
  scroll controls.
- Panel with now playing, a seek bar, transport buttons, search, results and
  the queue, all usable from the keyboard.
- IPC commands: `toggle`, `playPause`, `next`, `previous`, `stop`,
  `search`, `playResult`.
- Settings: `showTitle`, `maxTitleChars`, `autoRadio`.
- Media keys and the Omarchy media widget through `mpv-mpris`.
