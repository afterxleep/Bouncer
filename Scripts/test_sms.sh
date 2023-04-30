# Note that you'll need to set the TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER 
#export TWILIO_ACCOUNT_SID="your_account_sid_here"
#export TWILIO_AUTH_TOKEN="your_auth_token_here"
#export TWILIO_PHONE_NUMBER="+1234567890" # Your Twilio phone number


#!/bin/bash

# Get the recipient's phone number and message body from command-line arguments
to_number=$1
message_body=$2

# Check if the phone number and message body are empty
if [[ -z "$to_number" || -z "$message_body" ]]; then
  echo "Usage: $0 <to_number> <message_body>"
  exit 1
fi

# Set the Twilio API URL and authentication credentials from environment variables
twilio_url="https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json"
twilio_auth="$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"

# Send the SMS message using cURL
curl -X POST "$twilio_url" \
--data-urlencode "To=$to_number" \
--data-urlencode "From=$TWILIO_PHONE_NUMBER" \
--data-urlencode "Body=$message_body" \
-u "$twilio_auth"