#!/bin/bash

#---------------------------------------------------------------------------------------------
# Message Functions

count_messages() {
  CONTEXT=$(format_to_json "$CONTEXT")
  array_length=$(echo "$CONTEXT" | jq 'length')

  echo $array_length
}


clear_all() {
  > "$LOG_PATH"
}

clear_messages() {

  clear_count=$1
  
  # Remove all elements if clear_count value is too big
  if [[ $clear_count -ge $(count_messages) ]]; then
    clear_all

  # Remove first clear_count elements from the array
  else 

    CONTEXT=$(echo "$(format_to_json "$CONTEXT")" | jq ".[$clear_count:]")

    # Format it back
    CONTEXT=$(format_from_json "$CONTEXT")

    echo "$CONTEXT" > "$LOG_PATH"
  
  fi
}

#-------------------------------------------------------------------------------------------
# Arg function
check_mutual_exclusiveness() {
  if [[ "$FLAG_PRESENT" == true ]]; then
    echo "Flags must be mutually exclusive!"
    exit 1
  fi

  FLAG_PRESENT=true
}

#------------------------------------------------------------------------------------------
# JSON functions
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
#-------------------------------------------------------------------------------------

# START

#-------------------------------------------------------------------------------------

# Define global values

# Relative path
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LOG_PATH="$SCRIPT_DIR/.log"
HELP_PATH="$SCRIPT_DIR/help.txt"

# Model inputs
mode="You are a friendly AI model that needs to give short and concise answers."
CONTEXT=$(<"$LOG_PATH")

# Conversation history limit
MESSAGE_LIMIT=6

# For checking mutual exclusiveness
FLAG_PRESENT=false 

#-----------------------------------------------------------------------------------------

# Start error cases
if [ "$#" -eq 0 ]; then
  echo "Error: No prompt provided."
  echo "Usage: $0 \"Your prompt here\""
  exit 1
fi

# Get gemini env key from relative path
source "$SCRIPT_DIR/gemini.env"

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY not set"
  exit 1
fi
# End error cases

#------------------------------------------------------------------------------------------

# Parse flags

params="$(getopt -o :cslhn -l config --name "$0" -- "$@")"

eval set -- "$params"


while true
do
  case "$1" in
      -s)
        check_mutual_exclusiveness
        mode="You are a friendly AI model that needs to give short and concise answers."
        shift
      ;;
      -l)
        check_mutual_exclusiveness
        mode="You are an AI model that needs to give long and detailed answers."
        shift
        ;;
      -n)
        check_mutual_exclusiveness

        echo "Your conversation has $(count_messages) messages."
        exit 0
      ;;
      -c)
        check_mutual_exclusiveness
        
        shift
        
        if [[ -z "$2" ]]; then # If -c is used with no arguments
          clear_all
          echo "AI conversation history has been cleared."

        elif [[ ! "$2" =~ ^[0-9]+$ ]]; then # If -c is used with bad arguments
          echo "Error: -c option requires a valid number."
          exit 1

        else # If -c is used with a number argument
          clear_count="$2"
          clear_messages "$clear_count"
          echo "Cleared the first $clear_count messages from the conversation."

        fi
        
        exit 0
      ;;
      -h)
        check_mutual_exclusiveness
        cat $HELP_PATH
        exit 0
      ;;
      --config)
        echo "WORK IN PROGRESS"
        shift
        exit 0
      ;;
      
      --)
        shift
        break
      ;;
      
      *)
        echo "Not implemented: $1" >&2
        exit 1
      ;;

  esac



done


#----------------------------------------------------------------------------------

# Get remaining arguments (the prompt) and send them to Gemini API.
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


#-----------------------------------------------------------------------------------------------------
# Update .log file

# Append both user prompt and model response to the log
CONTEXT="${CONTEXT}
{\"role\":\"user\",\"parts\":[{\"text\":\"$PROMPT\"}]},
{\"role\":\"model\",\"parts\":[{\"text\":\"$escaped_reply\"}]},"


echo "$CONTEXT" > "$LOG_PATH"

# If message count goes over limit, delete first messages
if [[ $(count_messages) -gt $MESSAGE_LIMIT ]]; then
  clear_messages $(( $(count_messages) - $MESSAGE_LIMIT ))
fi
