import boto3 
from botocore.exceptions import BotoCoreError, ClientError
from contextlib import closing
import os
import sys
import time
from tempfile import gettempdir
import hashlib
import requests

'''
request
{
  "id": "ec876a8c-d37a4fe2-b7a1-7fbd2d23046a",
  "name": "Test Tester",
  "birth_date": "04/12/2023, 12:00 AM",
  "death_date": "2023-04-16T04:51:05.816Z",
  "image_url": "http://res.cloudinary.com/du5wbd7af/image/upload/v1681624029/i0dvv2et87hntuqrmgqg.png",
  "obituary": "Test Tester, born on April 12, 2023, at 12:00 a.m., passed away on April 16, at 4:51 p.m. She was a dedicated tester who always put the needs of her team first. Test Tester will be deeply missed, but her legacy will live on through the countless tests she conducted."
}

response
{
  "id": "ec876a8c-d37a4fe2-b7a1-7fbd2d23046a",
  "name": "Test Tester",
  "birth_date": "04/12/2023, 12:00 AM",
  "death_date": "2023-04-16T04:51:05.816Z",
  "obituary": "Test Tester, born on April 12, 2023, at 12:00 a.m., passed away on April 16, at 4:51 p.m. She was a dedicated tester who always put the needs of her team first. Test Tester will be deeply missed, but her legacy will live on through the countless tests she conducted.",
  "image_url": "http://res.cloudinary.com/du5wbd7af/image/upload/v1681624029/i0dvv2et87hntuqrmgqg.png",
  "mp3_url": "http://res.cloudinary.com/du5wbd7af/raw/upload/v1681624781/c3rtcmwkgjygud6votgq.mp3"
}

'''
# STEP 2
def lambda_handler(event, context):

    id = event["id"]
    obituary = event["obituary"]
    name = event["name"]

    recording_dir = "/tmp/recording/mp3"
    filename = name.replace(" ", "") + "-" + id + ".mp3"

    print("Obituary: ", obituary)

    try:
        polly = boto3.client("polly")
        # Request speech synthesis
        response = polly.synthesize_speech(Text=obituary, OutputFormat="mp3",
                                            VoiceId="Emma")
        
    except (BotoCoreError, ClientError) as error:
        # The service returned an error, exit gracefully
        print(error)
        sys.exit(-1)

    # Access the audio stream from the response
    if "AudioStream" in response:
        # Note: Closing the stream is important because the service throttles on the
        # number of parallel connections. Here we are using contextlib.closing to
        # ensure the close method of the stream object will be called automatically
        # at the end of the with statement's scope.
            with closing(response["AudioStream"]) as stream:

                if not os.path.exists(recording_dir):
                    os.makedirs(recording_dir)

                output = os.path.join(recording_dir, filename)

                try:
                    # Open a file for writing the output as a binary stream
                    with open(output, "wb") as file:
                        file.write(stream.read())
                except IOError as error:
                    # Could not write to file, exit gracefully
                    print(error)
                    sys.exit(-1)

                # Upload to cloudinary
                result = upload(recording_dir, filename)

                return {
                    "id": id,
                    "name": name,
                    "birth_date": event["birth_date"],
                    "death_date": event["death_date"],
                    "obituary": obituary,
                    "image_url": event["image_url"],
                    "mp3_url": result["url"]
                }


    else:
        # The response didn't contain audio data, exit gracefully
        print("Could not stream audio")
        sys.exit(-1)

    # # Play the audio using the platform's default player
    # if sys.platform == "win32":
    #     os.startfile(output)
    # else:
    #     # The following works on macOS and Linux. (Darwin = mac, xdg-open = linux).
    #     opener = "open" if sys.platform == "darwin" else "xdg-open"
    #     subprocess.call([opener, output])


def upload(mp3_file_path, filename):

    print("Intiating upload. Fetching file from " + mp3_file_path + " with filename " + filename)

    ssm_client = boto3.client('ssm')
    cloud_name = ssm_client.get_parameter(Name="/cloudinary/cloudname")
    api_key = ssm_client.get_parameter(Name="/cloudinary/apikey", WithDecryption=True)
    api_secret = ssm_client.get_parameter(Name="/cloudinary/apisecret", WithDecryption=True)

    cloud_name = cloud_name['Parameter']['Value']
    api_key = api_key['Parameter']['Value']
    api_secret = api_secret['Parameter']['Value']

    url = f"https://api.cloudinary.com/v1_1/{cloud_name}/raw/upload"
    timestamp = str(int(time.time()))

    request = {
        "signature": "",
        "api_key": api_key,
        "timestamp": timestamp,
    }

    # Generate the signature for the request
    signature = hashlib.sha1(f"timestamp={request['timestamp']}{api_secret}".encode()).hexdigest()
    request['signature'] = signature

    with open(f"{mp3_file_path}/{filename}", 'rb') as f:
        mp3_data = f.read()
        response = requests.post(url, params=request, files={'file': (filename, mp3_data)})

    if (response.status_code != 200):
        print(response)
        raise Exception("Unable to upload mp3")
    
    print(response.json())

    return response.json()

        