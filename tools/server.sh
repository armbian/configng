#!/bin/bash

# Check if python3 is installed
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found"
    exit
fi

# Get the IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Change to the directory where the script is located
cd "$(dirname "$0")"


# Start the Python server in the background
for port in {8000..8100}; do
    # Check if the port is in use
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        # Get the name of the command using the port
        command_name=$(ps -p $(lsof -t -i:$port) -o comm=)
        echo "Port $port is in use by $command_name"
        continue
    fi

    # Start the server
    echo "Starting server on port $port..."
    python3 -m http.server $port > /tmp/config.log 2>&1 &
    server_pid=$!

    # Wait for the server to start
    sleep 1

    # Check if the server is running
    if kill -0 $server_pid 2>/dev/null; then
        echo -e "\nServer started at IP: $IP_ADDRESS Port: $port"
        echo -e "Press enter to stop the server."
        read -p ""
        kill $server_pid
        echo "Server stopped."
        break
    else
        echo "Failed to start server on port $port"
    fi
done