
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
	apt-get install -y jq curl docker.io git nodejs npm golang && \
	npm install -g npx uvx

WORKDIR /app

COPY . .

# Run the script
CMD ["bash", "run-mcp-from-json.sh"]
