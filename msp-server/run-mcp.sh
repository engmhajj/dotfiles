#!/bin/bash
set -e

# Example environment variables (replace with your actual secrets or export beforehand)
export GITHUB_PERSONAL_ACCESS_TOKEN="your_github_token_here"
export GOOGLE_MAPS_API_KEY="your_google_maps_api_key_here"
export TAVILY_API_KEY="your_tavily_api_key_here"

# Base paths (update these paths accordingly)
PUBLIC_DIR="/Users/mohamadelhajhassan/code/public"
MCP_TOOLS_DIR="$PUBLIC_DIR/mcp-tools"

echo "Starting MCP services..."

# 1. GitHub MCP Server (Docker)
echo "Launching GitHub MCP server..."
docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server

# 2. Google Maps MCP Server (disabled - skipping)
echo "Google Maps MCP server is disabled. Skipping..."

# 3. Git MCP Server (uvx)
echo "Launching Git MCP server..."
uvx mcp-server-git

# 4. Fetch MCP Server (uvx)
echo "Launching Fetch MCP server..."
uvx mcp-server-fetch

# 5. Tavily MCP Server (disabled - skipping)
echo "Tavily MCP server is disabled. Skipping..."

# 6. Filesystem MCP Server (npx)
echo "Launching Filesystem MCP server..."
npx -y @modelcontextprotocol/server-filesystem "$PUBLIC_DIR"

# 7. Go MCP Tools Server
echo "Launching Go MCP Tools server..."
go -C "$MCP_TOOLS_DIR" run ./cmd/mcp-tools/main.go
