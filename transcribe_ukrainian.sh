#!/bin/bash

# Configuration
file_path=$1
transcribe_url="https://api.openai.com/v1/audio/transcriptions"
file_out=/tmp/"$(date +%Y%m%d%H%M)_UK_subtitles.crt"

# Prompt for API key
read -sp "Enter your OpenAI API key: " api_key
echo "" # Move to a new line after input

# Check file size (in MB)
file_size=$(du -m "$file_path" | cut -f1)
max_size=25

# Function to perform API call
perform_transcribe_call() {
    local part_path=$1
    curl --request POST \
         --url $transcribe_url \
         --header "Authorization: Bearer $api_key" \
         --header 'Content-Type: multipart/form-data' \
         --form file=@"$part_path" \
         --form model=whisper-1 \
	 -F language="uk" \
         -F response_format="srt" \
	 -o $file_out
    echo "SRT Ukrainian Language: $file_out"
}


# Check file size (in MB)
file_size=$(du -m "$file_path" | cut -f1)

if [ "$file_size" -le "$max_size" ]; then
    perform_transcribe_call "$file_path"
else
    mkdir -p /tmp/temp_audio_parts
    ffmpeg -i "$file_path" -f segment -segment_time 300 -c copy /tmp/temp_audio_parts/out%03d.mp3
    for part in /tmp/temp_audio_parts/*.mp3; do
        perform_transcribe_call "$part"
    done
fi

