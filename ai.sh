#!/bin/bash

mode="You are an AI model that needs to give short and concise answers."
LOG_PATH="/home/mario/logs/ai.log"



# Parse flags
while getopts ":slch" opt; do
  case $opt in
    s)
      mode="You are an AI model that needs to give short and concise answers."
      ;;
    l)
      mode="You are an AI model that needs to give long and detailed answers."
      ;;
    c)
      > "$LOG_PATH"
      echo "AI conversation history has been cleared."
      exit 0
      ;;
    h)
      echo "Usage: $0 [-s | -l | -c | -h] <Your prompt here>"
      echo
      echo "Flags:"
      echo "  -s    Short answer (default)"
      echo "  -l    Long and detailed answer"
      echo "  -c    Clear conversation history"
      echo "  -h    Show this help message"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))



# Start error cases
if [[ "$@" == *"-s"* && "$@" == *"-l"* ]]; then
  echo "Error: -s and -l are mutually exclusive."
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo "Error: No prompt provided."
  echo "Usage: $0 \"Your prompt here\""
  exit 1
fi

source ~/envs/gemini.env
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY not set"
  exit 1
fi
# End error cases



PROMPT="$@"
CONTEXT=$(<"$LOG_PATH")


REQUEST_BODY=$(cat <<EOF
{
  "system_instruction": {
      "parts": [
        {
          "text": "$mode"
        }
      ]
    },
  "contents": [
    $CONTEXT
    {"role": "user", "parts": [{"text": "$PROMPT"}]}
  ]
}
EOF
)

# Call Gemini API
response=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY")

model_reply=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')

# Escape JSON-sensitive characters for logging
escaped_reply=$(printf "%s" "$model_reply" | jq -Rs . | sed 's/^"\(.*\)"$/\1/')

# Show the reply
echo -e "\n$model_reply\n" | glow

# Append both user prompt and model response to the log
echo "{\"role\":\"user\",\"parts\":[{\"text\":\"$PROMPT\"}]}," >> "$LOG_PATH"
echo "{\"role\":\"model\",\"parts\":[{\"text\":\"$escaped_reply\"}]}," >> "$LOG_PATH"
