import requests
import json
import boto3

# STEP 1
'''
request
{
    "id": "ec876a8c-d37a4fe2-b7a1-7fbd2d23046a",
    "name": "Test Tester",
    "birth_date": "04/12/2023, 12:00 AM",
    "death_date": "2023-04-16T04:51:05.816Z",
    "image_url": "http://res.cloudinary.com/du5wbd7af/image/upload/v1681624029/i0dvv2et87hntuqrmgqg.png"
}

response
{
  "id": "ec876a8c-d37a4fe2-b7a1-7fbd2d23046a",
  "name": "Test Tester",
  "birth_date": "04/12/2023, 12:00 AM",
  "death_date": "2023-04-16T04:51:05.816Z",
  "image_url": "http://res.cloudinary.com/du5wbd7af/image/upload/v1681624029/i0dvv2et87hntuqrmgqg.png",
  "obituary": "Test Tester, born on April 12, 2023, at 12:00 a.m., passed away on April 16, at 4:51 p.m. She was a dedicated tester who always put the needs of her team first. Test Tester will be deeply missed, but her legacy will live on through the countless tests she conducted."
}
'''
def lambda_handler(event, context):
    
    print("Initialize generation")
    print(event)

    prompt = create_prompt(event["name"], event["birth_date"], event["death_date"])
    print("Prompt: " + prompt)

    obituary = create_obituary(prompt)
    print(obituary)

    return {
        "id": event["id"],
        "name": event["name"],
        "birth_date": event["birth_date"],
        "death_date": event["death_date"],
        "image_url": event["image_url"],
        "obituary": obituary.replace("\n", "")
    }

def create_prompt(name, birth_date, death_date):

    return f'write an obituary about a fictional character named {name} who was born on {birth_date} and died on {death_date}.'

def create_obituary(prompt):

    open_ai_url = "https://api.openai.com/v1/completions"
    body = {
        "model": "text-curie-001",
        "prompt": prompt,
        "max_tokens": 650,
        "temperature": 0,
        "top_p": 1,
        "n": 1,
        "stream": False,
    }

    ssm_client = boto3.client('ssm')
    api_key = ssm_client.get_parameter(Name="/openai/apikey", WithDecryption=True)

    headers = {"Authorization": "Bearer " + api_key['Parameter']['Value']}

    response = requests.post(open_ai_url, json=body, headers=headers)

    print(response.json())

    text = response.json()["choices"][0]["text"]

    return text

