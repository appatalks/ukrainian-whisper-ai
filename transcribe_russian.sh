#!/bin/bash

# Configuration
file_path=$1
transcribe_url="https://api.openai.com/v1/audio/transcriptions"
mkdir -p tmp
file_out=tmp/"$(date +%Y%m%d%H%M)_RU_subtitles.srt"

# Authentication
auth() {
    OPENAI_API_KEY=$(cat "config.json" | jq -r '.OPENAI_API_KEY')
}

auth

# Check file size (in MB)
file_size=$(du -m "$file_path" | cut -f1)
max_size=25

# Function to perform API call
perform_api_call() {
    local part_path=$1
    local part_out=$2
    curl --request POST \
         --url $base_url \
         --header "Authorization: Bearer ${OPENAI_API_KEY}" \
         --header 'Content-Type: multipart/form-data' \
         --form file=@"$part_path" \
         --form model=whisper-1 \
	 -F language="ru" \
         -F response_format="srt" \
         -o "$part_out"
    echo "SRT Russian Lanugage Output to: $part_out"
}

# Function to shift SRT timestamps
shift_srt_timestamps() {
    local srt_file=$1
    local shift_seconds=$2
    local temp_file=$(mktemp)

    awk -v shift=$shift_seconds '
    function shift_time(t) {
        split(t, a, /[:,]/)
        secs = a[1] * 3600 + a[2] * 60 + a[3] + a[4] / 1000 + shift
        h = int(secs / 3600)
        m = int((secs % 3600) / 60)
        s = int(secs % 60)
        ms = (secs - int(secs)) * 1000
        return sprintf("%02d:%02d:%02d,%03d", h, m, s, ms)
    }
    {
        if ($0 ~ /--> /) {
            split($0, times, " --> ")
            print shift_time(times[1]) " --> " shift_time(times[2])
        } else {
            print $0
        }
    }' "$srt_file" > "$temp_file"

    mv "$temp_file" "$srt_file"
}

combined_srt="tmp/combined_$(date +%Y%m%d%H%M%S)_RU_Subtitles.srt"
touch "$combined_srt"

if [ "$file_size" -le "$max_size" ]; then
    # File is within the size limit, perform API call
    part_out="tmp/$(date +%Y%m%d%H%M%S)_RU_Subtitles.srt"
    perform_api_call "$file_path" "$part_out"
    cat "$part_out" >> "$combined_srt"
else
    # File exceeds the size limit, process segments one at a time
    mkdir -p /tmp/temp_audio_parts
    duration=$(ffprobe -i "$file_path" -show_entries format=duration -v quiet -of csv="p=0")
    segment_time=600
    total_segments=$(echo "($duration + $segment_time - 1)/$segment_time" | bc)

    for (( segment=0; segment<$total_segments; segment++ )); do
        start_time=$(echo "$segment * $segment_time" | bc)
        part_path="/tmp/temp_audio_parts/out${segment}.mp3"
        part_out="tmp/$(date +%Y%m%d%H%M%S)_RU_Subtitles_part${segment}.srt"
        ffmpeg -i "$file_path" -ss $start_time -t $segment_time -c copy "$part_path"

        if [ -f "$part_path" ]; then
            echo "Performing API Call on segment ${segment}"
            perform_api_call "$part_path" "$part_out"

            # Adjust the SRT timestamps for the combined SRT file
            shift_seconds=$(echo "$segment * $segment_time" | bc)
            adjusted_srt=$(mktemp)
            cp "$part_out" "$adjusted_srt"
            shift_srt_timestamps "$adjusted_srt" "$shift_seconds"
            cat "$adjusted_srt" >> "$combined_srt"
            rm "$adjusted_srt"
        fi

        sleep 2
    done
fi

echo "Combined SRT file created at: $combined_srt"

