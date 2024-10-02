#!/bin/bash

# Get voicemail URL from config.json
voicemail_url=$(jq -r '.voicemail_url' ./config.json)
csv_url=$(jq -r '.csv_url' ./config.json)
port=$(jq -r '.port' ./config.json)

# Get ngrok URL from user
read -p "Ngrok URL [ends with ngrok-free.app]: " ngrok_url

# Validate the ngrok URL
if [[ ! $ngrok_url =~ ^https?:// ]]; then
    echo "Invalid ngrok URL. It should start with http:// or https://"
    exit 1
fi

# Remove trailing slash if present
ngrok_url=${ngrok_url%/}
ngrok_url=${ngrok_url/#https:/http:}

# Download the CSV file
csv_file="phone_numbers.csv"
wget -O "$csv_file" "$csv_url"

if [ $? -ne 0 ]; then
    echo "Failed to download CSV file. Exiting."
    exit 1
fi
# Extract phone numbers from CSV
phone_numbers=$(awk -F ',' 'NR>1 {gsub(/[^0-9]/, "", $1); print substr($1, length($1)-9)}' "$csv_file")

encoded_voicemail_url=$(python -c "import urllib.parse; print(urllib.parse.quote('$voicemail_url'))")

#Iterate over phone numbers
for phone_number in $phone_numbers; do
    formatted_phone_number="+1$phone_number"
    python script.py --voicemail_mp3=$voicemail_url --phone_number=$formatted_phone_number --ngrok_url=$ngrok_url --port=$port &
    # Wait for the Python script to finish
    wait $!

    if [ $? -ne 0 ]; then
        echo "Python script exited with an error."
    else
        echo "Python script completed successfully."
    fi
done

# Kill any process running on port $port
port_pid=$(lsof -i :$port | awk 'NR>1 {print $2}')

# Clean up
rm $csv_file

echo "Script completed."