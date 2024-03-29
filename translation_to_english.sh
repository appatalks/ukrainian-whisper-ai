#!/bin/bash

# Configuration
file_path=$1
file_out=/tmp/"$(date +%Y%m%d%H%M)_ENG_Subtitles.srt"
base_url="https://api.openai.com/v1/audio/translations"

# Prompt for API key
read -sp "Enter your OpenAI API key: " api_key
echo "" # Move to a new line after input

# Check file size (in MB)
file_size=$(du -m "$file_path" | cut -f1)
max_size=25

# Function to perform API call
perform_api_call() {
    local part_path=$1
    curl --request POST \
         --url $base_url \
         --header "Authorization: Bearer $api_key" \
         --header 'Content-Type: multipart/form-data' \
         --form file=@"$part_path" \
         --form model=whisper-1 \
         -F response_format="srt" \
         -o "$file_out"
    echo "SRT English Output to: $file_out"
}


if [ "$file_size" -le "$max_size" ]; then
    # File is within the size limit, perform API call
    perform_api_call "$file_path"
else
    # File exceeds the size limit, split and call API for each part
    mkdir -p /tmp/temp_audio_parts
    ffmpeg -i "$file_path" -f segment -segment_time 300 -c copy /tmp/temp_audio_parts/out%03d.mp3
    
    for part in /tmp/temp_audio_parts/*.mp3; do
        perform_api_call "$part"
    done
fi

