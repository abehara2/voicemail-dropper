#!/bin/bash
# Check if pip is installed
if ! command -v pip &> /dev/null
then
    echo "pip is not installed. Installing pip..."
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    rm get-pip.py
fi

# Check if brew is installed
if ! command -v brew &> /dev/null
then
    echo "Homebrew is not installed. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for the current session
    eval "$(/opt/homebrew/bin/brew shellenv)"
    
    # Add Homebrew to PATH permanently
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
    
    echo "Homebrew has been installed and added to PATH."
else
    echo "Homebrew is already installed."
fi

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null
then
    echo "ngrok is not installed. Installing ngrok..."
    brew install ngrok/ngrok/ngrok
    ngrok config add-authtoken 2m2EzKQYhRw4tjb27y3RXn5nJVc_5Qx7xd1dCKBRdyWXDZQFc
    
    if [ $? -ne 0 ]; then
        echo "Failed to install ngrok using Homebrew. Please install it manually."
        exit 1
    fi
    
    echo "ngrok has been installed successfully."
else
    echo "ngrok is already installed."
fi

# Check if twilio is installed
if ! pip list | grep -F twilio &> /dev/null
then
    echo "Twilio is not installed. Installing twilio..."
    pip install twilio
fi

# Check if twilio is installed
if ! pip list | grep -F flask &> /dev/null
then
    echo "Flask is not installed. Installing Flask..."
    pip install flask
fi

# Get port from config.json
port=$(jq -r '.port' ./config.json)

# Check if port was successfully retrieved
if [ -z "$port" ]; then
    echo "Failed to retrieve port from config.json. Exiting."
    exit 1
fi

# Check if port is in use and kill associated processes
if lsof -i :$port > /dev/null 2>&1; then
    echo "Port $port is in use. Attempting to kill associated processes..."
    sudo lsof -ti :$port | xargs kill -9
    pkill -f ngrok
    sleep 2
fi


echo "Starting ngrok on port $port..."

# Run ngrok
ngrok http $port

# Check if ngrok started successfully
if [ $? -ne 0 ]; then
    echo "Failed to start ngrok. Exiting."
    exit 1
fi
