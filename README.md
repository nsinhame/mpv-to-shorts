# MPV to Shorts

A powerful bash script that automates the creation of Shorts from longer videos using MPV media player, mpv-webm plugin and FFmpeg.

## What It Does

This script bridges the gap between MPV's audio extraction capabilities and FFmpeg's video trimming features to create a seamless workflow for generating Shorts.

**Workflow:**
1. **mpv-webm** → Extracts audio clips with timestamps from your video
2. **mpv-shorts.sh** → Processes audio files to extract timestamps
3. **FFmpeg** → Trims original video based on timestamps
4. **Result** → Multiple short video clips ready for Shorts


## Prerequisites

- **Bash**: Unix shell (Linux, macOS, WSL on Windows)
- **FFmpeg**: For video processing
- **MPV Media Player**: With audio extraction extension mpv-webm


## Usage

### Basic Usage

```bash
./mpv-shorts.sh your_video.mp4
```

### Example Workflow

1. **Prepare your files:**
```
your_project/
├── my_tutorial.mp4                     # Your source video
├── audio1-[12.39.792-13.28.574].mp3   # Extracted from MPV
├── audio2-[59.34.070-1.00.15.445].mp3 # Extracted from MPV
└── mpv-shorts.sh                       # This script
```

2. **Run the script:**
```bash
./mpv-shorts.sh my_tutorial.mp4
```

3. **Results:**
```
your_project/
├── my_tutorial.mp4                     # Original video
├── mpv-shorts.sh                       # Script
├── trimmed_videos/                     # 🎉 Your Shorts!
│   ├── trimmed_video_part_1.mp4
│   └── trimmed_video_part_2.mp4
└── cache/                              # Processed files
    ├── timestamps.txt
    ├── audio1-[12.39.792-13.28.574].mp3
    └── audio2-[59.34.070-1.00.15.445].mp3
```

## File Naming Requirements

The script looks for MP3 files with timestamp information in square brackets:

**Supported formats:**
- `audio-[12.39.792-13.28.574].mp3`
- `clip1-[1.23.456-2.34.567].mp3`
- `my_extract-[59.34.070-1.00.15.445].mp3`

**Will be skipped:**
- `background_music.mp3` (no timestamp)
- `narration.mp3` (no timestamp)

**Timestamp formats supported:**
- `MM.SS.mmm` → Converts to `00:MM:SS.mmm`
- `HH.MM.SS.mmm` → Converts to `HH:MM:SS.mmm`

## MPV Plugin: mpv-webm

**mpv-webm** - Simple WebM maker for mpv, with no external dependencies.

This plugin is perfect for our workflow as it can:
- Extract video/audio segments with precise timestamps
- Save clips with timestamp information in filenames
- Work seamlessly with our script's timestamp parsing

## Configuration

The script uses these default settings:

- **Output Directory**: `trimmed_videos/`
- **Cache Directory**: `cache/`
- **Video Codec**: `libx264`
- **CRF**: `18` (high quality)
- **Audio Codec**: `aac`

You can modify these in the script if needed.


## Debug Mode

For verbose output, you can modify the FFmpeg command in the script:
```bash
# Change from:
ffmpeg -i "$INPUT_VIDEO" -ss "$START_TIME" -to "$END_TIME" -loglevel error -stats -c:v libx264 -crf 18 -c:a aac "$OUTPUT_FILE"

# To:
ffmpeg -i "$INPUT_VIDEO" -ss "$START_TIME" -to "$END_TIME" -loglevel info -c:v libx264 -crf 18 -c:a aac "$OUTPUT_FILE"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.


## License

This project is free to use by anyone. You can use, modify, and distribute this software without any restrictions.

## Acknowledgments

- **[MPV Media Player](https://mpv.io/)** - For excellent media playback and extensibility
- **[FFmpeg](https://ffmpeg.org/)** - For powerful video processing capabilities
- **[mpv-webm](https://github.com/ekisu/mpv-webm)** - For the simple WebM maker plugin that enables seamless audio extraction
- **Shorts** - For inspiring the creation of bite-sized content (and admittedly, for being delightfully addictive time-wasters)


---

**Made with ❤️ for content creators who want to efficiently create Shorts from longer videos.**
