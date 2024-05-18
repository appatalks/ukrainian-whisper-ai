# Subtitle Magic
# Combine Subtitle breaks of < 750ms to same blocks 
#
# Usage: $ python sub_magic.py in.srt

import pysrt
from datetime import datetime

# Load the subtitles from a file
subs = pysrt.open('in.srt')

# List to hold the merged subtitles
combined_subs = []
temp_sub = subs[0]  # Start with the first subtitle

# Iterate over the remaining subtitles
for sub in subs[1:]:
    # Check the gap between current and next subtitle
    if (sub.start.ordinal - temp_sub.end.ordinal) <= 750:  # 2000 milliseconds or 2 seconds
        # Combine the text of subtitles if they are close enough
        temp_sub.text += ' ' + sub.text
        temp_sub.end = sub.end
    else:
        # If they are not close enough, store the current temp_sub and start a new group
        combined_subs.append(temp_sub)
        temp_sub = sub

# Append the last subtitle group
combined_subs.append(temp_sub)

# Generate a timestamp in the format YYYYMMDD_HHMMSS
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

# Save the new file with merged subtitles and timestamp
new_file = f'combined_output_{timestamp}.srt'
pysrt.SubRipFile(items=combined_subs).save(new_file)

print(f"Combined subtitles saved to {new_file}")

