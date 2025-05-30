#!/bin/bash
set -e

CONFIG_FILE="mcp-config.json"
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Configurable parameters
MAX_RESTARTS=5
RESTART_WINDOW=60 # seconds
MAX_BACKOFF=60    # max backoff seconds

declare -A RESTART_TIMES

# Trap Ctrl+C for graceful shutdown
shutdown() {
	echo "Caught SIGINT, stopping all services..."
	pkill -P $$ || true
	exit 0
}
trap shutdown SIGINT

wait_backoff() {
	local attempt=$1
	# Exponential backoff capped at MAX_BACKOFF
	local delay=$((2 ** attempt))
	if ((delay > MAX_BACKOFF)); then
		delay=$MAX_BACKOFF
	fi
	echo "Waiting $delay seconds before restarting..."
	sleep $delay
}

# Record restart time and check if restart attempts exceed limit
check_restarts() {
	local name=$1
	local now=$(date +%s)
	# Remove old restart times outside window
	RESTART_TIMES[$name]=$(echo "${RESTART_TIMES[$name]}" | tr ' ' '\n' | awk -v now=$now -v win=$RESTART_WINDOW '$0 > now - win' | tr '\n' ' ')
	# Add current restart time
	RESTART_TIMES[$name]="${RESTART_TIMES[$name]} $now"
	# Count restarts in window
	local count=$(echo "${RESTART_TIMES[$name]}" | wc -w)
	if ((count > MAX_RESTARTS)); then
		return 1
	else
		return 0
	fi
}

notify_failure() {
	local name=$1
	echo "⚠️ Service $name is restarting too frequently! Please investigate." >&2
	# TODO: Hook email/slack/webhook notifications here
}

run_service() {
	local name=$1
	local cmd=$2
	local args=$3
	local env_vars=$4
	local health_url=$5
	local health_host=$6
	local health_port=$7

	local log_file="$LOG_DIR/$name.log"
	local env_file=".env.$name"

	local attempt=0

	echo "Launching service $name..."

	while true; do
		# Check restart attempts
		if ! check_restarts "$name"; then
			notify_failure "$name"
			echo "Too many restarts for $name. Sleeping for $MAX_BACKOFF seconds."
			sleep $MAX_BACKOFF
			# Reset restart times after cooldown
			RESTART_TIMES[$name]=""
			attempt=0
		fi

		echo "=== Starting $name at $(date) ===" | tee -a "$log_file"

		if [[ -f "$env_file" ]]; then
			echo "Loading env from $env_file"
			# shellcheck disable=SC1090
			source "$env_file"
		fi

		# Run service in background
		env $env_vars $cmd $args >>"$log_file" 2>&1 &
		local pid=$!

		sleep 3

		# Health check
		if [[ -n "$health_url" ]]; then
			if ! wait_for_http "$health_url"; then
				echo "Health check failed for $name. Killing process." | tee -a "$log_file"
				kill $pid || true
				wait $pid || true
				wait_backoff $attempt
				((attempt++))
				continue
			fi
		elif [[ -n "$health_host" && -n "$health_port" ]]; then
			if ! wait_for_port "$health_host" "$health_port"; then
				echo "Port check failed for $name. Killing process." | tee -a "$log_file"
				kill $pid || true
				wait $pid || true
				wait_backoff $attempt
				((attempt++))
				continue
			fi
		else
			echo "No health check configured for $name, assuming service ready."
		fi

		wait $pid
		echo "Service $name exited at $(date). Restarting..." | tee -a "$log_file"
		wait_backoff $attempt
		((attempt++))
	done
}

# Wait helpers (same as before)
wait_for_http() {
	local url=$1
	local max_wait=30
	local waited=0
	echo "Waiting for HTTP health check at $url ..."
	while ((waited < max_wait)); do
		if curl --silent --fail "$url" >/dev/null; then
			echo "Health check passed at $url"
			return 0
		fi
		sleep 2
		((waited += 2))
	done
	echo "Health check failed: timeout waiting for $url"
	return 1
}

wait_for_port() {
	local host=$1
	local port=$2
	local max_wait=30
	local waited=0
	echo "Waiting for TCP port $host:$port ..."
	while ((waited < max_wait)); do
		if nc -z "$host" "$port"; then
			echo "Port $host:$port is open"
			return 0
		fi
		sleep 2
		((waited += 2))
	done
	echo "Port check failed: timeout waiting for $host:$port"
	return 1
}

echo "Starting MCP services with smarter auto-restart, health checks, and logging..."

jq -c '.mcpServers | to_entries[]' "$CONFIG_FILE" | while read -r entry; do
	NAME=$(echo "$entry" | jq -r '.key')
	DISABLED=$(echo "$entry" | jq -r '.value.disabled // false')

	if [[ "$DISABLED" == "true" ]]; then
		echo "Service '$NAME' is disabled. Skipping."
		continue
	fi

	CMD=$(echo "$entry" | jq -r '.value.command')
	ARGS=$(echo "$entry" | jq -r '.value.args | join(" ")')
	ENV_VARS=$(echo "$entry" | jq -r '.value.env // {} | to_entries | map("\(.key)=\(.value // "")") | join(" ")')

	HEALTH_URL=$(echo "$entry" | jq -r '.value.health.url // empty')
	HEALTH_HOST=$(echo "$entry" | jq -r '.value.health.host // empty')
	HEALTH_PORT=$(echo "$entry" | jq -r '.value.health.port // empty')

	run_service "$NAME" "$CMD" "$ARGS" "$ENV_VARS" "$HEALTH_URL" "$HEALTH_HOST" "$HEALTH_PORT" &

	echo "Service '$NAME' started."
done

wait
