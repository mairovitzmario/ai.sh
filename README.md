# AI Chat Script

A command-line interface for chatting with Google's Gemini AI model. This script maintains conversation history and provides flexible response modes.

## Prerequisites

- **bash** shell
- **curl** - for API requests
- **jq** - for JSON parsing
- **glow** - for markdown rendering (optional, for better output formatting)


## Setup

1. **Get a Gemini API Key:**
   - Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key

2. **Configure the API Key:**
   Create a `gemini.env` file in the same directory as the script:
   ```bash
   echo "GEMINI_API_KEY=your_api_key_here" > gemini.env
   ```

3. **Make the script executable:**
   ```bash
   chmod +x ai
   ```

4. **Optional: Add to PATH**
   ```bash
   # Add to your ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/your/script/directory"
   ```

## Usage

### Basic Usage
```bash
./ai "Your question here"
```

### Flags

- **`-s`** - Short and concise answers (default mode)
- **`-l`** - Long and detailed answers
- **`-c [number]`** - Clear conversation history
  - Without number: clears all history
  - With number: clears first N messages
- **`-n`** - Show number of messages in conversation
- **`-h`** - Show help message

### Examples

**Basic question:**
```bash
./ai "What is the capital of France?"
```

**Request detailed answer:**
```bash
./ai -l "Explain how machine learning works"
```

**Check conversation length:**
```bash
./ai -n
```

**Clear entire conversation:**
```bash
./ai -c
```

**Clear first 4 messages:**
```bash
./ai -c 4
```

**Get help:**
```bash
./ai -h
```

## Features

- **Conversation Memory**: Maintains chat history in `.log` file
- **Flexible Response Modes**: Choose between short or detailed responses
- **History Management**: View, clear, or partially clear conversation history
- **Error Handling**: Comprehensive input validation and error messages
- **Markdown Rendering**: Beautiful output formatting with glow

## Files

- `ai` - Main script executable
- `gemini.env` - API key configuration (create this file)
- `.log` - Conversation history (auto-generated)
- `.gitignore` - Excludes environment files from git

## Troubleshooting

**"GEMINI_API_KEY not set" error:**
- Ensure `gemini.env` file exists with your API key
- Check that the file is in the same directory as the script

**"command not found" errors:**
- Install missing dependencies (curl, jq, glow)
- Ensure the script is executable (`chmod +x ai`)

**JSON parsing errors:**
- Check your internet connection
- Verify your API key is valid and has quota remaining

## Security Note

Keep your `gemini.env` file secure and never commit it to version control. The `.gitignore` file is configured to exclude `*.env` files.