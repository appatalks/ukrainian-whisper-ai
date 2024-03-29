#!/bin/bash

# Configuration
file_path=$1
transcribe_url="https://api.openai.com/v1/audio/transcriptions"
chat_url="https://api.openai.com/v1/chat/completions"
file_out=/tmp/"$(date +%Y%m%d%H%M)_transcribe_response.json"
translate_out=/tmp/"$(date +%Y%m%d%H%M)_translate_response.json"	

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
}

#if [ "$file_size" -le "$max_size" ]; then
#    # File is within the size limit, perform API call
#    perform_transcribe_call "$file_path"
#else
#    mkdir -p /tmp/temp_audio_parts
#    ffmpeg -i "$file_path" -f segment -segment_time 300 -c copy /tmp/temp_audio_parts/out%03d.mp3
#    
#    for part in /tmp/temp_audio_parts/*.mp3; do
#        perform_transcribe_call "$part"
#    done
#fi

# Function to append AI generated English translation of Ukrainian text.
perform_translation_call() {
    local temp_json=$(mktemp)
    cat <<EOF > "$temp_json"
{
  "model": "gpt-4-turbo-preview",
  "messages": [
    {
      "role": "system",
      "content": "Append on new line after the srt timestamps both the English translation and the Ukrainian text where each line it is found."
    },
    {
      "role": "user",
      "content": "$(cat $file_out)"
    }
  ]
}
EOF

    curl -s $chat_url \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $api_key" \
      -d @"$temp_json" | jq -r '.choices[].message.content' | sed 's/\([0-9]\{2,3\}:[0-9]\{2\}:[0-9]\{2\},[0-9]\{3\} --> [0-9]\{2,3\}:[0-9]\{2\}:[0-9]\{2\},[0-9]\{3\}\)/\n\1\n/g' > "$translate_out.srt"

    # Clean up temporary file
    rm "$temp_json"

    echo "SRT Output to: $file_out"
    echo "SRT Translation Output to: $translate_out.srt"
}

# Check file size (in MB)
file_size=$(du -m "$file_path" | cut -f1)

if [ "$file_size" -le "$max_size" ]; then
    perform_transcribe_call "$file_path"
    perform_translation_call
else
    mkdir -p /tmp/temp_audio_parts
    ffmpeg -i "$file_path" -f segment -segment_time 300 -c copy /tmp/temp_audio_parts/out%03d.mp3
    for part in /tmp/temp_audio_parts/*.mp3; do
        perform_transcribe_call "$part"
        perform_translation_call
    done
fi

