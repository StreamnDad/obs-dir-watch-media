# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OBS Studio plugin (by Exeldro) that adds a **video filter** which watches a directory for media files and automatically updates the parent source. Current version: **0.7.0**.

## Build

### In-tree (recommended)
1. Clone into `obs-studio/plugins/dir-watch-media`
2. Add `add_subdirectory(dir-watch-media)` to `plugins/CMakeLists.txt`
3. Build OBS Studio normally

### Out-of-tree (Linux only)
```bash
cmake -S . -B build -DBUILD_OUT_OF_TREE=On && cmake --build build
```

## Architecture

This is a single-source-file C plugin (`dir-watch-media.c` + `dir-watch-media.h`).

### Plugin Type
Registered as `OBS_SOURCE_TYPE_FILTER` with `OBS_SOURCE_VIDEO` output flags. It attaches as a filter to a parent source and manipulates the parent's settings — it does **not** produce its own video output (`video_render` just calls `obs_source_skip_video_filter`).

### Supported Parent Source Types
The filter detects the parent source type and updates it accordingly:
- **`ffmpeg_source`** — sets `local_file` + triggers `restart` proc handler
- **`vlc_source`** — appends to `playlist` array (prevents duplicates)
- **`image_source` / `xObsAsyncImageSource`** — sets `file` property

### Core Loop
`dir_watch_media_source_tick` runs each video frame:
1. Handles pending file deletions (`delete_file`)
2. Registers hotkeys on first tick (lazy init via `hotkeys_added` flag)
3. Scans the watched directory at configurable `scan_interval` (ms)
4. Selects a file based on `sort_by` (created/modified newest/oldest, alphabetical, random)
5. Applies `filter` (substring match on filename) and `extension` filters
6. Verifies file is openable (`os_fopen` with `rb+`) before updating parent

### Hotkey Actions
Registered per-source (not per-filter): Clear, Random, Refresh, Remove First/Last, Delete First/Last. Remove/Delete hotkeys only registered for VLC sources.

### Versioning
Version is set in `CMakeLists.txt` (`project(dir-watch-media VERSION X.Y.Z)`) and flows through `version.h.in` → `version.h`. Also duplicated in `buildspec.json`.

## Localization

Locale files in `data/locale/`. Supported: en-US, de-DE, fr-FR, nl-NL. Translation keys prefixed with `DWM.`.

## CI/CD

GitHub Actions workflow in `.github/workflows/build.yml` builds for Windows, macOS, and Linux using scripts in `.github/scripts/`.
