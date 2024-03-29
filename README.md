# ukrainian-whisper-ai 
## OpenAI Audio Transcription and Translation Script

> [!IMPORTANT] 
> Transcribe Ukrainian with translation to English text to SRT format. OpenAI transcription API Endpoint

Leverages the OpenAI API to transcribe audio files and translate the transcriptions into English. Initially, it transcribes audio using OpenAI's Whisper model, specifically targeting Ukrainian language audio for transcription. Following transcription, the script employs OpenAI's GPT model to append English translations to the SRT (SubRip subtitle) file generated from the transcription process. This tool is designed to handle audio files directly, manage file size constraints by splitting large files, and process both the transcription and translation phases automatically.

## Features

- **Transcription**: Converts audio to text using the Whisper model, with a focus on Ukrainian audio content.
- **Translation**: Appends English translations to the SRT file, ensuring that both the original Ukrainian text and its English translation are included.
- **File Size Management**: Splits files larger than 25MB into smaller segments to comply with API limitations.
- **Automated Workflow**: From a single audio file input, produces an SRT file containing both transcribed and translated text.

## Requirements

- Bash shell (Linux, macOS)
- `curl` for making API requests
- `ffmpeg` for splitting large audio files into manageable segments
- `jq` for parsing JSON responses

## Setup

1. Ensure all required tools (`curl`, `ffmpeg`, `jq`) are installed on your system.
2. Place the script in a desired directory.

## Usage

1. Open a terminal and navigate to the directory containing the script.
2. Make the script executable with the following command:

```chmod +x run.sh```

3. Run the script by providing the path to the audio file as an argument:

```bash ./run.sh /path/to/your/audio_file.mp3```

4. When prompted, enter your OpenAI API key. This key is required to authenticate API requests for transcription and translation.

## Important Notes

- The script is designed to work with audio files specifically in the Ukrainian language for the initial transcription process. Adjustments may be needed for other languages.
- API costs: Using the OpenAI API for transcription and translation may incur costs. Please check the current OpenAI pricing and your usage quota before running the script.

## Output

- The script generates two main outputs:
- A `.json` file with the transcribed text in Ukrainian.
- An `.srt` file with both the original Ukrainian transcription and the appended English translation, ready for use as subtitles.

