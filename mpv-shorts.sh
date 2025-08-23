#!/bin/bash

# Combined Video Splitter Script
# This script extracts timestamps from audio files and trims a video based on those timestamps

# Check if the input video file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <input_video_file>"
    echo "This script will:"
    echo "  1. Extract timestamps from all .mp3 files with [timestamp] in filename"
    echo "  2. Trim the provided video file based on those timestamps"
    echo "  3. Save trimmed videos in the 'trimmed_videos' directory"
    echo "  4. Move processed files to 'cache' directory"
    echo ""
    echo "Example: $0 myvideo.mp4"
    echo "  Will process any .mp3 files like: audio-[12.39.792-13.28.574].mp3"
    exit 1
fi

INPUT_VIDEO="$1"
TIMESTAMPS_FILE="timestamps.txt"
# Create session-based output directory with timestamp
SESSION_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="trimmed_videos/session_${SESSION_TIMESTAMP}"

# Check if input video file exists
if [ ! -f "$INPUT_VIDEO" ]; then
    echo "Error: Input video file '$INPUT_VIDEO' not found."
    exit 1
fi

# Check if input video has .mp4 extension
if [[ ! "$INPUT_VIDEO" =~ \.mp4$ ]]; then
    echo "Error: Input video file must have .mp4 extension."
    exit 1
fi

# Extract the base filename without extension for reference
VIDEO_BASENAME=$(basename "$INPUT_VIDEO" .mp4)

echo "=== Shorts Video Splitter ==="
echo "Input video: $INPUT_VIDEO"
echo "Looking for audio files: *.mp3 (with timestamps in filename)"
echo

# ===== TIMESTAMP EXTRACTION PHASE =====
echo "Phase 1: Extracting timestamps from audio files..."

# Clear the output file or create a new one
> "$TIMESTAMPS_FILE"

# Function to format a single timestamp
format_timestamp() {
  local time_part=$1
  # Check if the format is HH.MM.SS.mmm
  if [[ $(echo "$time_part" | grep -o '\.' | wc -l) -eq 3 ]]; then
    # HH.MM.SS.mmm -> HH:MM:SS.mmm
    echo "$time_part" | sed 's/\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/\1:\2:\3.\4/g'
  # Check if the format is MM.SS.mmm
  elif [[ $(echo "$time_part" | grep -o '\.' | wc -l) -eq 2 ]]; then
    # MM.SS.mmm -> 00:MM:SS.mmm
    echo "$time_part" | sed 's/\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)/00:\1:\2.\3/g'
  else
    # If the format doesn't match, just output the original string
    echo "$time_part"
  fi
}

# Check if any audio files exist
audio_files_found=false
for file in *.mp3; do
  if [ -f "$file" ]; then
    audio_files_found=true
    break
  fi
done

if [ "$audio_files_found" = false ]; then
    echo "Error: No .mp3 files found in the current directory."
    echo "Please ensure audio files with timestamp information are present."
    echo "Expected pattern: any filename with [timestamp] in the name and .mp3 extension"
    exit 1
fi

# Loop through all MP3 files
timestamp_count=0
for file in *.mp3; do
  if [ -f "$file" ]; then
    echo "Processing: $file"
    
    # Extract the timestamp string between the brackets
    timestamp_string=$(echo "$file" | sed -n 's/.*\[\(.*\)\].*/\1/p')

    # Only process files that have timestamp information in brackets
    if [ -z "$timestamp_string" ]; then
      echo "Skipping $file (no timestamp found in brackets)"
      continue
    fi

    # Separate the start and end timestamps
    start_time=$(echo "$timestamp_string" | cut -d'-' -f1)
    end_time=$(echo "$timestamp_string" | cut -d'-' -f2)

    # Format both timestamps
    formatted_start=$(format_timestamp "$start_time")
    formatted_end=$(format_timestamp "$end_time")

    # Combine them with a hyphen and output to the file
    if [ -n "$formatted_start" ] && [ -n "$formatted_end" ]; then
      echo "$formatted_start-$formatted_end" >> "$TIMESTAMPS_FILE"
      timestamp_count=$((timestamp_count+1))
      echo "  → Extracted: $formatted_start-$formatted_end"
    fi
  fi
done

echo "Timestamps extracted and saved to $TIMESTAMPS_FILE"
echo "Total timestamps found: $timestamp_count"
echo

# Check if timestamps were extracted
if [ $timestamp_count -eq 0 ]; then
    echo "Error: No valid timestamps were extracted."
    exit 1
fi

# ===== VIDEO TRIMMING PHASE =====
echo "Phase 2: Trimming video based on extracted timestamps..."

# Create session-based output directory
mkdir -p "$OUTPUT_DIR"

echo "Processing video: $INPUT_VIDEO"
echo "Session directory: $OUTPUT_DIR"
echo

# Read the timestamps file line by line
COUNT=1
while read -r line; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi

    # Extract start and end times
    START_TIME=$(echo "$line" | cut -d'-' -f1)
    END_TIME=$(echo "$line" | cut -d'-' -f2)

    # Generate an output filename
    OUTPUT_FILE="${OUTPUT_DIR}/trimmed_video_part_${COUNT}.mp4"

    echo "Trimming part $COUNT: from $START_TIME to $END_TIME"
    echo "Output: $OUTPUT_FILE"

    # Execute the ffmpeg command with reduced logging and progress stats
    ffmpeg -i "$INPUT_VIDEO" -ss "$START_TIME" -to "$END_TIME" -loglevel error -stats -c:v libx264 -crf 18 -c:a aac "$OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully created part $COUNT"
        
        # Calculate SHA-256 hash of the trimmed video
        echo "Calculating SHA-256 hash for uniqueness..."
        if command -v sha256sum &> /dev/null; then
            # Linux/WSL
            HASH=$(sha256sum "$OUTPUT_FILE" | cut -d' ' -f1)
        elif command -v shasum &> /dev/null; then
            # macOS
            HASH=$(shasum -a 256 "$OUTPUT_FILE" | cut -d' ' -f1)
        else
            echo "Warning: SHA-256 utility not found. Keeping original filename."
            HASH=""
        fi
        
        # Rename the file with the hash if hash was calculated successfully
        if [ -n "$HASH" ]; then
            HASH_OUTPUT_FILE="${OUTPUT_DIR}/${HASH}.mp4"
            mv "$OUTPUT_FILE" "$HASH_OUTPUT_FILE"
            echo "✓ Renamed to: ${HASH}.mp4"
            echo "  Hash: $HASH"
        fi
    else
        echo "✗ Error creating part $COUNT"
    fi
    echo

    # Increment counter
    COUNT=$((COUNT+1))
done < "$TIMESTAMPS_FILE"

# ===== CLEANUP PHASE =====
echo "Phase 3: Moving files to cache..."

CACHE_DIR="cache"
mkdir -p "$CACHE_DIR"

# Get current timestamp for file versioning (consistent with session naming)
CACHE_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Move timestamps.txt to cache with timestamp
if [ -f "$TIMESTAMPS_FILE" ]; then
    TIMESTAMPS_BASENAME=$(basename "$TIMESTAMPS_FILE" .txt)
    TIMESTAMPED_FILE="${TIMESTAMPS_BASENAME}_${CACHE_TIMESTAMP}.txt"
    mv "$TIMESTAMPS_FILE" "$CACHE_DIR/$TIMESTAMPED_FILE"
    echo "✓ Moved $TIMESTAMPS_FILE to $CACHE_DIR/$TIMESTAMPED_FILE"
fi

# Move all MP3 files with timestamps to cache
moved_audio_count=0
for file in *.mp3; do
    if [ -f "$file" ]; then
        # Only move files that have timestamp information in brackets
        timestamp_check=$(echo "$file" | sed -n 's/.*\[\(.*\)\].*/\1/p')
        if [ -n "$timestamp_check" ]; then
            # Extract filename without extension and add timestamp
            AUDIO_BASENAME=$(basename "$file" .mp3)
            TIMESTAMPED_AUDIO="${AUDIO_BASENAME}_${CACHE_TIMESTAMP}.mp3"
            mv "$file" "$CACHE_DIR/$TIMESTAMPED_AUDIO"
            echo "✓ Moved $file to $CACHE_DIR/$TIMESTAMPED_AUDIO"
            moved_audio_count=$((moved_audio_count+1))
        fi
    fi
done

echo "Total audio files moved to cache: $moved_audio_count"
echo

echo "=== PROCESSING COMPLETE ==="
echo "Original video: $INPUT_VIDEO"
echo "Cache directory: $CACHE_DIR"
echo "Session directory: $OUTPUT_DIR"
echo "Total parts created: $((COUNT-1))"
echo
echo "Your Shorts are ready in the '$OUTPUT_DIR' directory!"
echo "Processed files have been moved to the '$CACHE_DIR' directory."
