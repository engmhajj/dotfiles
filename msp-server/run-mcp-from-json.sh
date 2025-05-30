#!/bin/bash

CONFIG_FILE="mcp-config.json"

# Load environment variables from .env
if [ -f .env ]; then
	echo "🔄 Loading environment variables from .env"
	export $(grep -v '^#' .env | xargs)
fi

run_server() {
	name="$1"
	cmd="$2"
	args="$3"
	env_vars="$4"

	echo "$env_vars" | jq -r 'to_entries[] | "\(.key)=\(.value // env[\(.key)])"' | while IFS='=' read -r key value; do
		if [ -z "$value" ]; then
			echo "⚠️  Skipping $name: Missing required env var $key"
			return
		fi
		export "$key=$value"
	done

	echo "▶ Starting $name..."
	eval "$cmd $args" &
}

jq -r '.mcpServers | to_entries[] | select(.value.disabled != true) | @base64' "$CONFIG_FILE" | while read -r entry; do
	_jq() {
		echo "$entry" | base64 --decode | jq -r "$1"
	}

	name=$(_jq '.key')
	command=$(_jq '.value.command')
	args=$(_jq '.value.args | map(@sh) | join(" ")')
	env_vars=$(_jq '.value.env // {}')

	run_server "$name" "$command" "$args" "$env_vars"
done

wait
echo "✅ All enabled MCP servers started."
