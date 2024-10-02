from twilio.rest import Client
from twilio.twiml.voice_response import VoiceResponse
from flask import Flask
import argparse
import threading
import os

# Twilio credentials
account_sid = os.getenv('ACCOUNT_SID')
auth_token = os.getenv('AUTH_TOKEN')
client = Client(account_sid, auth_token)

# Your Twilio phone number
twilio_number = os.getenv('TWILIO_NUMBER')

# Flask app for handling webhooks
app = Flask(__name__)

@app.route("/voice", methods=['GET', 'POST'])
def voice():
    """Handle the call when it's answered, goes to voicemail, is declined, or the line is busy."""
    response = VoiceResponse()
    response.play(app.config['voicemail_mp3'])
    print("left voicemail")
    return str(response)

def make_call(ngrok_url, phone_number):
    """Initiate the call using Twilio."""
    call = client.calls.create(
        to=phone_number,
        from_=twilio_number,
        url=f"{ngrok_url}/voice",
        machine_detection='DetectMessageEnd',
    )
    print("ngrok url: ", ngrok_url)
    print("phone number: ", phone_number)
    print("voicemail mp3: ", app.config['voicemail_mp3'])

if __name__ == "__main__":
    # set args
    parser = argparse.ArgumentParser()
    parser.add_argument('--voicemail_mp3', type=str)
    parser.add_argument('--phone_number', type=str)
    parser.add_argument('--ngrok_url', type=str)
    parser.add_argument('--port', type=int)
    args = parser.parse_args()

    flask_thread = threading.Thread(target=app.run, kwargs={'port': args.port, 'debug': False})
    flask_thread.daemon = True  # Set as daemon thread
    flask_thread.start()

    app.config['voicemail_mp3'] = args.voicemail_mp3
    make_call(args.ngrok_url, args.phone_number)
    
    # Wait for the Flask thread to finish
    flask_thread.join(timeout=100)