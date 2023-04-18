import boto3
import os
import json
import time


# STEP 4
'''
request
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
def lambda_handler(event, context):

    dynamodb = boto3.resource("dynamodb")
    table_name = os.environ["TABLE_NAME"]
    table = dynamodb.Table(table_name)

    status = 201

    response = table.put_item(Item = {
        'id': event["id"],
        'name': event["name"],
        'birth_date': event["birth_date"],
        'death_date': event["death_date"],
        'obituary': event["obituary"],
        'image_url': event["image_url"],
        'mp3_url': event["mp3_url"],
        'created_at': str(int(time.time()))
        })
    
    return json.dumps({ 
        "status": status,
    })

