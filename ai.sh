#!/bin/bash
# This is a test
mode="You are a friendly AI model that needs to give short and concise answers."
LOG_PATH="/home/mario/logs/ai.log"
CONTEXT=$(<"$LOG_PATH")
FLAG_PRESENT=false

clear_all() {
  > "$LOG_PATH"
    echo "AI conversation history has been cleared."
}

check_mutual_exclusiveness() {
  if [[ "$FLAG_PRESENT" == true ]]; then
    echo "Flags must be mutually exclusive!"
    exit 1
  fi

  FLAG_PRESENT=true
}

format_to_json() {
  local txt=$1

  txt=${txt%,}
  txt="[$txt]"

  echo "$txt"
}


format_from_json() {
  local txt=$1

  txt=${txt%]}   
  txt=${txt#[}
  txt="$txt,"

  echo "$txt"
}

# Parse flags
while getopts ":cslhn" opt; do
  case $opt in
    s)
      check_mutual_exclusiveness
      mode="You are a friendly AI model that needs to give short and concise answers."
      ;;
    l)
      check_mutual_exclusiveness
      mode="You are an AI model that needs to give long and detailed answers."
      ;;
    n)
      check_mutual_exclusiveness
      CONTEXT=$(format_to_json "$CONTEXT")
        
      array_length=$(echo "$CONTEXT" | jq 'length')
      echo "Your conversation has $array_length messages."
      exit 0
    ;;
    c)
      check_mutual_exclusiveness
      if [[ -z "$2" ]]; then # If -c is used with no arguments
        clear_all

      elif [[ ! "$2" =~ ^[0-9]+$ ]]; then # If -c is used with bad arguments
        echo "Error: -c option requires a valid number."
        exit 1

      else # If -c is used with a number argument
        clear_count="$2"
        #clear_count=$((clear_count * 2))

        # Turn the log file into a JSON array
        CONTEXT=$(format_to_json "$CONTEXT")
        
        array_length=$(echo "$CONTEXT" | jq 'length')
        
        # Remove all elements if clear_count value is too big
        if [[ $clear_count -ge $array_length ]]; then
          clear_all

        # Remove first clear_count elements from the array
        else 
          CONTEXT=$(echo "$CONTEXT" | jq ".[$clear_count:]")

          # Format it back
          CONTEXT=$(format_from_json "$CONTEXT")

          echo "$CONTEXT" > "$LOG_PATH"

          echo "Cleared the first $clear_count messages from the conversation."
        
        fi
      fi
      
      exit 0
    ;;
    h)
      check_mutual_exclusiveness
      echo "Usage: $0 [-s | -l <PROMPT> ] [-h | -c <number> | -n]"
      echo
      echo "Flags:"
      echo "  -s    Short answer (default)"
      echo "  -l    Long and detailed answer. You must provide a prompt after this flag."
      echo "  -c    Clear conversation history. Optionally, provide a number to clear a specific number of messages from the start. If no number is provided, it deletes all conversation history."
      echo "  -n    Show the number of messages in the conversation."
      echo "  -h    Show this help message"
      echo
      echo "Note: All flags are mutually exclusive. You can only use one of -s, -l, -c, or -h at a time."
      echo "      The prompt is only allowed after the flags -s or -l. It should not be provided after -c or -h."
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
